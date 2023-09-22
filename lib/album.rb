# frozen_string_literal: true

class Album
  def initialize(path)
    @file = slugify(path.split("/")[1])
  end

  def slugify(string)
    string
      .gsub(/\s+/, "-")       # replace spaces with -
      .gsub("&", "-and-")     # replace & with -and-
      .gsub(%r{[^\w\-/]+}, "") # replace all non-word chars except - and /
      .gsub(%r{/}, "-")        # replace / with -
      .gsub(/--+/, "-") # replace multiple - with single -
      .gsub(%r{-/}, "/") # remove - before a /
      .gsub(/^-/, "")         # remove leading -
      .gsub(/-$/, "")         # remove trailing -
  end

  def filename
    @posts_dir = "../PhotosOfBlacklion.github.io/_posts"
    "#{@posts_dir}/#{year}/#{@file}.md"
  end

  def slug
    @slug ||= filename.match(/\d\d\d\d-\d\d-\d\d-(.*)\.md/)[1]
  end

  def title
    @title ||= slug.gsub(%r{/}, "-").gsub("-", " ").gsub(/\w+/, &:capitalize)
  end

  def year
    @year ||= (@file.match(/(\d\d\d\d)-\d\d-\d\d-.*/)[1]).to_s
  end

  def date
    @date ||= "#{filename.match(/(\d\d\d\d-\d\d-\d\d)-.*.md/)[1]} 12:00"
  end

  def exists?
    File.exist?(filename)
  end
end
