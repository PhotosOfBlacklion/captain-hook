require 'aws-sdk'
require 'dotenv'
require 'logger'
require 'net/http'
require 'rmagick'
require 'rugged'
require 'uri'
require 'yaml'
require File.expand_path('../tables', __FILE__)
require File.expand_path('../album', __FILE__)
require File.expand_path('../photo', __FILE__)

include Magick

class Hook
  def self.run!(options)
    Server.new(options).run!
  end

  def initialize
    Dotenv.load

    @pidfile = './pids/captain-hook.pid'
    @photos = []
    @logger = Logger.new('./logs/hook.log', 'daily')
    @logger.level = Logger::INFO
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    @bucket = 'photos-of-blacklion'
    @pages_dir = '../PhotosOfBlacklion.github.io/_posts'

  end

  def run!
    check_pid
    write_pid

    while file = get_file
      album = Album.new(file.path)
      photo = Photo.new(file.path)

      download(file.path, photo.title)
      delete(file.path)
      create_thumbnail(photo.title)
      copy_to_s3(photo)
      delete_temp_files(photo.title)
      add_photo(album, photo)
    end
  end

  def write_pid
    begin
      File.open(@pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
      at_exit { File.delete(@pidfile) if File.exists?(@pidfile) }
    rescue Errno::EEXIST
      check_pid
      retry
    end
  end

  def check_pid
    case pid_status(@pidfile)
    when :running, :not_owned
      puts "A server is already running. Check #{@pidfile}"
      exit(1)
    when :dead
      File.delete(@pidfile)
    end
  end

  def pid_status(pidfile)
    return :exited unless File.exists?(pidfile)
    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid)      # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

  def get_file
    Dropbox.first(:processed => false)
  end

  def delete_temp_files(photo)
    @logger.info("Deleting local temporary files")
    File.delete(photo, "t_#{photo}")
  end

  def add_photo(album, photo)
    if album.exists?
      contents = YAML.load(File.open(album.filename))
      contents['photos'] << {
        "original" => photo.original,
        "thumbnail" => photo.thumbnail,
        "title" => photo.title
      }
      File.open(album.filename, 'w') do |f|
        f.puts "---"
        f.puts "title: #{album.title}"
        f.puts "date: #{album.date}"
        f.puts "thumbnail: #{photo.thumbnail}"
        f.puts "photos:"
        contents['photos'].each do |p|
          f.puts "  - original: #{p['original']}"
          f.puts "    thumbnail: #{p['thumbnail']}"
          f.puts "    title: #{p['title']}"
        end
        f.puts '---'
      end
    else
      File.open(album.filename, 'w') do |f|
        f.puts "---"
        f.puts "title: #{album.title}"
        f.puts "date: #{album.date}"
        f.puts "thumbnail: #{photo.thumbnail}"
        f.puts "photos:"
        f.puts "  - original: #{photo.original}"
        f.puts "    thumbnail: #{photo.thumbnail}"
        f.puts "    title: #{photo.title}"
        f.puts '---'
      end
    end
  end

  def download(source, target)
    @logger.info("Downloading and saving #{source} to be worked on")
    url = 'https://content.dropboxapi.com/2/files/download'
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)

    request['Content-Type'] = ''
    request['Authorization'] = "Bearer #{ENV['DROPBOX_ACCESS_TOKEN']}"
    request['Dropbox-API-Arg'] = '{"path":"' + source + '"}'

    response = http.request(request)

    File.open(target, 'w') do |f|
      f.puts response.body
    end
  end

  def delete(path)
    @logger.info("Deleting the photo from Dropbox")
    body = { path: "#{path}" }
    url = 'https://api.dropboxapi.com/2/files/delete'
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = body.to_json

    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['DROPBOX_ACCESS_TOKEN']}"

    http.request(request)
  end

  def create_thumbnail(photo)
    @logger.info("Creating the thumbnail")
    img = ImageList.new(photo)
    thumb = img.change_geometry('200^') { |cols, rows, img|
      img.resize!(cols, rows)
    }.crop(CenterGravity, 0,0,200,200)
    thumb.write("t_#{photo}")
  end

  def copy_to_s3(photo)
    @logger.info("Copying #{photo.title} to s3://#{@bucket}/#{photo.s3_path}.")
    s3 = Aws::S3::Resource.new(region: 'eu-west-1')
    obj = s3.bucket(@bucket).object(photo.s3_path)
    obj.upload_file(photo.title)
    @logger.info("Copying t_#{photo.title} to s3://#{@bucket}/t/#{photo.s3_path}.")
    obj = s3.bucket(@bucket).object("t/#{photo.s3_path}")
    obj.upload_file("t_#{photo.title}")
  end

  def create_jekyll_page
    @logger.info("Creating the final Jekyll page")
    File.open(album_name, 'w') do |f|
      f.puts "---"
      f.puts "title: #{title}"
      f.puts "date: #{date}"
      f.puts "thumbnail: #{thumbnail}"
      f.puts "photos:"
      @photos.flatten.each do |photo|
        f.puts "  - original: #{photo['original']}"
        f.puts "    thumbnail: #{photo['thumbnail']}"
        f.puts "    title: #{photo['title']}"
      end
      f.puts '---'
    end
  end

  def commit
    /(?<commit_file>_posts\/.*)/ =~ album_name
    repo = Rugged::Repository.discover(@pages_dir)
    index = repo.index
    index.add(path: commit_file,
              oid: (Rugged::Blob.from_workdir(repo, commit_file)),
              mode: 0100644
             )
    commit_tree = index.write_tree(repo)
    index.write
    commit_author = { email: 'hook@mikegriffin.ie', name: 'Captain Hook', time: Time.now }
    Rugged::Commit.create(repo,
                          author: commit_author,
                          committer: commit_author,
                          message: "Adds #{title}",
                          parents: [repo.head.target],
                          tree: commit_tree,
                          update_ref: 'HEAD'
                         )
    credentials = Rugged::Credentials::UserPassword.new(username: "mgriffin", password: ENV['GH_TOKEN'])
    repo.push('origin', ['refs/heads/master'], {credentials: credentials})
  end
end
