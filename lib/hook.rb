require 'aws-sdk'
require 'dotenv'
require 'logger'
require 'mysql2'
require 'net/http'
require 'rmagick'
require 'uri'
require 'yaml'

include Magick

class Hook
  def initialize
    Dotenv.load

    @photos = []
    @logger = Logger.new('captain-hook.log', 'daily')
    @logger.level = Logger::INFO
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    @bucket = 'photos-of-blacklion'
    @pages_dir = '../PhotosOfBlacklion.github.io/_posts'

    @mysql = Mysql2::Client.new(
      :host => 'localhost',
      :username => 'hook',
      :password => ENV['MYSQL_PASSWORD'],
      :database => 'hooks'
    )
  end

  def are_we_running?
    @pidfile = './captain-hook.pid'
    if File.exists?(@pidfile)
      @logger.info("Exiting because I'm already running")
      exit
    end
    File.open(@pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f| f.write("#{Process.pid}") }
    at_exit { File.delete(@pidfile) if File.exists?(@pidfile) }
  end

  def get_photo_paths
    @logger.info("Getting the photo paths")
    sql = "SELECT path FROM files WHERE processed = FALSE"
    result = []
    @mysql.query(sql).each do |row|
      result << row['path']
    end
    return result
  end

  def extract_parts(photo_path)
    @logger.info("Extracting the year, months, day and slug")
    directory = photo_path.split('/')[1]
    @filename = photo_path.split('/')[2]
    /(?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)-(?<slug>.*)/ =~ directory
    @year = year
    @month = month
    @day = day
    @slug = slug
  end

  def delete_temp_files(photo)
    @logger.info("Deleting local temporary files")
    filename = photo.split('/')[2]
    File.delete(filename, "t_#{filename}")
  end

  def add_photo(original)
    @logger.info("Adding the processed photo (#{original}) to the array")
    @photos.push [ 'original' => original, 'thumbnail' => "/t#{original}", 'title' => @filename ]
    sql = "UPDATE files SET processed = true WHERE path = \"#{original}\""
    @mysql.query(sql)
  end

  def album_name
    @logger.info("Creating the album filename")
    "#{@pages_dir}/#{@year}-#{@month}-#{@day}-#{@slug}.md"
  end

  def download(path)
    @logger.info("Downloading and saving #{path} to be worked on")
    url = 'https://content.dropboxapi.com/2/files/download'
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)

    request['Content-Type'] = ''
    request['Authorization'] = "Bearer #{ENV['DROPBOX_ACCESS_TOKEN']}"
    request['Dropbox-API-Arg'] = '{"path":"' + path +'"}'

    response = http.request(request)

    File.open(@filename, 'w') do |f|
      f.puts response.body
    end
  end

  def delete(path)
    @logger.info("Deleting the photo from Dropbox")
    body = { path: path }
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
    filename = photo.split('/')[2]
    img = ImageList.new(filename)
    thumb = img.change_geometry('200^') { |cols, rows, img|
      img.resize!(cols, rows)
    }.crop(CenterGravity, 0,0,200,200)
    thumb.write("t_#{filename}")
  end

  def copy_to_s3(photo)
    filename = photo.split('/')[2]
    path = "#{@year}/#{@month}/#{@slug}/#{filename}"
    @logger.info("Copying #{filename} to s3://#{@bucket}/#{path}.")
    s3 = Aws::S3::Resource.new(region: 'eu-west-1')
    obj = s3.bucket(@bucket).object(path)
    obj.upload_file(filename)
    @logger.info("Copying t_#{filename} to s3://#{@bucket}/t/#{path}.")
    obj = s3.bucket(@bucket).object("t/#{path}")
    obj.upload_file("t_#{filename}")
  end

  def title
    @logger.info("Title casing the title again")
    @slug.gsub(/\//, '-').gsub(/-/, ' ').gsub(/\w+/) do |word|
      word.capitalize
    end
  end

  def date
    @logger.info("Getting the date for the album")
    "#{@year}-#{@month}-#{@day} 12:00"
  end

  def thumbnail
    @logger.info("Getting the album thumbnail")
    @photos.flatten.first['thumbnail']
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
end
