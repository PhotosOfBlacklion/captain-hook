class Photo
  attr_reader :processed

  def initialize(path)
    /(?<year>\d\d\d\d)-(?<month>\d\d)-(\d\d)-(?<slug>.*)\/(?<filename>.*\.jpg)/ =~ path
    @year = year
    @month = month
    @slug = slug
    @filename = filename
  end

  def s3_path
    @s3_path ||= "#{@year}/#{@month}/#{@slug}/#{@filename}"
  end

  def original
    @original ||= "/#{@year}/#{@month}/#{@slug}/#{@filename}"
  end

  def thumbnail
    @thumbnail ||= "/t#{original}"
  end

  def title
    @title ||= "#{@filename}"
  end
end
