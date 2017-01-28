class Photo
  attr_reader :filename
  attr_reader :path
  attr_reader :processed

  def initialize(the_path)
    path = the_path
    /(?<year>\d\d\d\d)-(?<month>\d\d)-(\d\d)-(?<slug>.*)\/(?<filename>.*\.jpg)/ =~ path
    @year = year
    @month = month
    @slug = slug
    @filename = filename
  end

  def s3_path
    @s3_path ||= "#{@year}/#{@month}/#{@slug}/#{@filename}"
  end
end
