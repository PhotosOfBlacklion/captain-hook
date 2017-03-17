class Album

  def initialize(path)
    @file = slugify(path.split('/')[1])
  end

  def slugify(string)
    string
    .gsub(/\s+/, '-')       # replace spaces with -
    .gsub(/&/, '-and-')     # replace & with -and-
    .gsub(/[^\w\-\/]+/, '') # replace all non-word chars except - and /
    .gsub(/\//, '-')        # replace / with -
    .gsub(/\-\-+/, '-')     # replace multiple - with single -
    .gsub(/-\//, '/')       # remove - before a /
    .gsub(/^-/, '')         # remove leading -
    .gsub(/-$/, '')         # remove trailing -
  end

  def filename
    @posts_dir = "../PhotosOfBlacklion.github.io/_posts"
    "#{@posts_dir}/#{@file}.md"
  end

  def slug
    @slug ||= filename.match(/\d\d\d\d-\d\d-\d\d-(.*)\.md/)[1]
  end

  def title
    @title ||= slug.gsub(/\//, '-').gsub(/-/, ' ').gsub(/\w+/) do |word|
      word.capitalize
    end
  end

  def date
    @date ||= "#{filename.match(/(\d\d\d\d-\d\d-\d\d)-.*.md/)[1]} 12:00"
  end
end
