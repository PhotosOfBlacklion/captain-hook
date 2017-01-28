require_relative "test_helper"

class AlbumTest < CaptainHook::Test
  def setup
    path = "2017-01-17-mike-test"
    @album = Album.new(path)
  end

  def test_year
    assert @album.year == "2017", "The album year is wrong"
  end

  def test_month
    assert @album.month == "01", "The album month is wrong"
  end

  def test_day
    assert @album.day == "17", "The album day is wrong"
  end

  def test_slug
    assert @album.slug == "mike-test", "The album slug is wrong"
  end

  def test_title
    assert @album.title == "Mike Test", "The album title is wrong"
  end

  def test_filename
    assert @album.filename == "../PhotosOfBlacklion.github.io/_posts/2017-01-17-mike-test.md", "The album filename is wrong"
  end
end
