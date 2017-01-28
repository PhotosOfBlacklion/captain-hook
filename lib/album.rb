class Album
  attr_reader :filename

  def initialize(slug)
    posts_dir = "../PhotosOfBlacklion.github.io/_posts"
    @filename = "#{posts_dir}/#{slug}.md"
  end

  def year
    @year ||= @filename.match(/(\d\d\d\d)-\d\d-\d\d-.*/)[1]
  end

  def month
    @month ||= @filename.match(/\d\d\d\d-(\d\d)-\d\d-.*/)[1]
  end

  def day
    @day ||= @filename.match(/\d\d\d\d-\d\d-(\d\d)-.*/)[1]
  end

  def slug
    @slug ||= @filename.match(/\d\d\d\d-\d\d-\d\d-(.*)\.md/)[1]
  end

  def title
    @title ||= slug.gsub(/\//, '-').gsub(/-/, ' ').gsub(/\w+/) do |word|
      word.capitalize
    end
  end
end
