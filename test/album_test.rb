# frozen_string_literal: true

require_relative "test_helper"

class AlbumTest < CaptainHookTest
  def setup
    path = "/2017-01-17-mike-test/first.jpg"
    @album = Album.new(path)
  end

  def test_slug
    assert_equal("mike-test", @album.slug, "The album slug is wrong -- #{@album.slug}")
  end

  def test_title
    assert_equal("Mike Test", @album.title, "The album title is wrong -- #{@album.title}")
  end

  def test_filename
    assert_equal("../PhotosOfBlacklion.github.io/_posts/2017/2017-01-17-mike-test.md", @album.filename, "The album filename is wrong -- `#{@album.filename}`")
  end

  def test_date
    assert_equal("2017-01-17 12:00", @album.date, "The album date is wrong, #{@album.date}")
  end

  def test_directory_with_spaces_has_them_removed
    path = "/2017-02-23-storm-doris-dismantles-pier at lough mac nean blacklion county cavan/02-img_0039.jpg"
    album = Album.new(path)

    assert_equal("Storm Doris Dismantles Pier At Lough Mac Nean Blacklion County Cavan", album.title, "The album title is wrong -- #{album.title}")
    assert_equal("../PhotosOfBlacklion.github.io/_posts/2017/2017-02-23-storm-doris-dismantles-pier-at-lough-mac-nean-blacklion-county-cavan.md", album.filename, "The album filename is wrong -- #{album.filename}")
    assert_equal("2017-02-23 12:00", album.date, "The ablbum date is wrong -- #{album.date}")
  end
end
