# frozen_string_literal: true

require "aws-sdk"
require "dotenv"
require "logger"
require "net/http"
require "rmagick"
require "rugged"
require "uri"
require "yaml"
require File.expand_path("album", __dir__)
require File.expand_path("models/dropbox", __dir__)
require File.expand_path("photo", __dir__)

class Hook
  include Magick

  def self.run!
    Hook.new.run!
  end

  def initialize
    Dotenv.load

    @pidfile = "./pids/captain-hook.pid"
    @photos = []
    @logger = Logger.new("./logs/hook.log", "daily")
    @logger.level = Logger::INFO
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S"

    @bucket = "photos-of-blacklion"
    @pages_dir = "../PhotosOfBlacklion.github.io/_posts"
  end

  def run!
    check_pid
    write_pid
    git_pull(@pages_dir)

    commit_files = []
    while file = get_file
      album = Album.new(file.path)
      photo = Photo.new(file.path)
      commit_files << album.filename

      begin
        download(file.path, photo.title, file.user)
      rescue StandardError
        @logger.info("#{file.path} doesn't exist, skipping")
        file.update(processed: true, updated_at: Time.now)
        next
      end
      delete(file.path, file.user)
      begin
        create_thumbnail(photo.title)
        copy_to_s3(photo)
        delete_temp_files(photo.title)
        add_photo(album, photo)
      rescue StandardError
        @logger.info("#{file.path} wasn't downloaded properly, skipping")
        file.update(processed: true, updated_at: Time.now)
        next
      end
      file.update(processed: true, updated_at: Time.now)
    end

    commit_files.uniq.each do |a|
      git_commit(@pages_dir, a)
    end
    git_push(@pages_dir)
  end

  def write_pid
    File.open(@pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f| f.write(Process.pid.to_s) }
    at_exit { File.delete(@pidfile) if File.exist?(@pidfile) }
  rescue Errno::EEXIST
    check_pid
    retry
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
    return :exited unless File.exist?(pidfile)

    pid = ::File.read(pidfile).to_i
    return :dead if pid.zero?

    Process.kill(0, pid) # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

  def get_file
    Dropbox.first(processed: false)
  end

  def delete_temp_files(photo)
    @logger.info("Deleting local temporary files")
    File.delete(photo, "t_#{photo}")
  end

  def add_photo(album, photo)
    if album.exists?
      contents = YAML.safe_load(File.open(album.filename))
      contents["photos"] << {
        "original" => photo.original,
        "thumbnail" => photo.thumbnail,
        "title" => photo.title
      }
      # sort by file name
      contents["photos"].sort_by! { |h| h["original"] }
      # remove duplicates
      contents["photos"].uniq! { |e| e["original"] }

      File.open(album.filename, "w") do |f|
        f.puts "---"
        f.puts "title: #{album.title}"
        f.puts "date: #{album.date}"
        f.puts "thumbnail: #{contents['thumbnail']}"
        f.puts "photos:"
        contents["photos"].each do |p|
          f.puts "  - original: #{p['original']}"
          f.puts "    thumbnail: #{p['thumbnail']}"
          f.puts "    title: #{p['title']}"
        end
        f.puts "---"
      end
    else
      File.open(album.filename, "w") do |f|
        f.puts "---"
        f.puts "title: #{album.title}"
        f.puts "date: #{album.date}"
        f.puts "thumbnail: #{photo.thumbnail}"
        f.puts "photos:"
        f.puts "  - original: #{photo.original}"
        f.puts "    thumbnail: #{photo.thumbnail}"
        f.puts "    title: #{photo.title}"
        f.puts "---"
      end
    end
  end

  def download(source, target, user)
    @logger.info("Downloading and saving #{source} to be worked on")
    url = "https://content.dropboxapi.com/2/files/download"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)

    token = Token.first(user:).token
    request["Content-Type"] = ""
    request["Authorization"] = "Bearer #{token}"
    request["Dropbox-API-Arg"] = "{\"path\":\"#{source}\"}"

    response = http.request(request)

    File.open(target, "w") do |f|
      f.puts response.body
    end
  end

  def delete(path, user)
    @logger.info("Deleting the photo from Dropbox")
    body = { path: path.to_s }
    url = "https://api.dropboxapi.com/2/files/delete"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = body.to_json

    token = Token.first(user:).token
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{token}"

    http.request(request)
  end

  def create_thumbnail(photo)
    @logger.info("Creating the thumbnail")
    img = ImageList.new(photo)
    thumb = img.change_geometry("200^") do |cols, rows, image|
      image.resize!(cols, rows)
    end.crop(CenterGravity, 0, 0, 200, 200)
    thumb.write("t_#{photo}")
  end

  def copy_to_s3(photo)
    @logger.info("Copying #{photo.title} to s3://#{@bucket}/#{photo.s3_path}.")
    s3 = Aws::S3::Resource.new(region: "eu-west-1")
    obj = s3.bucket(@bucket).object(photo.s3_path)
    obj.upload_file(photo.title)
    @logger.info("Copying t_#{photo.title} to s3://#{@bucket}/t/#{photo.s3_path}.")
    obj = s3.bucket(@bucket).object("t/#{photo.s3_path}")
    obj.upload_file("t_#{photo.title}")
  end

  def git_pull(repo)
    `cd #{repo} && git fetch && git pull`
  end

  def git_commit(repo, album)
    %r{(?<commit_file>_posts/.*)} =~ album
    repository = Rugged::Repository.discover(repo)
    index = repository.index
    index.add(path: commit_file,
              oid: Rugged::Blob.from_workdir(repository, commit_file),
              mode: 0o100644)
    commit_tree = index.write_tree(repository)
    index.write
    commit_author = { email: "hook@mikegriffin.ie", name: "Captain Hook", time: Time.now }
    Rugged::Commit.create(repository,
                          author: commit_author,
                          committer: commit_author,
                          message: "Adds things to #{commit_file}",
                          parents: [repository.head.target],
                          tree: commit_tree,
                          update_ref: "HEAD")
  end

  def git_push(repo)
    credentials = Rugged::Credentials::UserPassword.new(username: "mgriffin", password: ENV["GH_TOKEN"])
    repository = Rugged::Repository.discover(repo)
    repository.push("origin", ["refs/heads/master"], { credentials: })
  end
end
