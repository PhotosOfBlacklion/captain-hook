class Photo
  attr_reader :processed

  def initialize(path)
    file = slugify(path)
    /(?<year>\d\d\d\d)-(?<month>\d\d)-(\d\d)-(?<slug>.*)\/(?<filename>.*\.jpg)/ =~ file
    @year = year
    @month = month
    @slug = slug
    @filename = filename
  end

  def slugify(string)
    string
    .gsub(/\s+/, '-')       # replace spaces with -
    .gsub(/&/, '-and-')     # replace & with -and-
    .gsub(/[^\w\-\/\.]+/, '') # replace all non-word chars except - and /
    .gsub(/\-\-+/, '-')     # replace multiple - with single -
    .gsub(/-\//, '/')       # remove - before a /
    .gsub(/^-/, '')         # remove leading -
    .gsub(/-$/, '')         # remove trailing -
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
