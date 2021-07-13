# frozen_string_literal: true

require_relative 'test_helper'

class AlbumTest < CaptainHook::Test
  def setup
    path = '/2017-01-17-mike-test/first.jpg'
    @album = Album.new(path)
  end

  def test_slug
    assert @album.slug == 'mike-test',
           "The album slug is wrong -- #{@album.slug}"
  end

  def test_title
    assert @album.title == 'Mike Test',
           "The album title is wrong -- #{@album.title}"
  end

  def test_filename
    assert @album.filename == '../PhotosOfBlacklion.github.io/_posts/2017/2017-01-17-mike-test.md',
           "The album filename is wrong -- `#{@album.filename}`"
  end

  def test_date
    assert @album.date == '2017-01-17 12:00',
           "The album date is wrong, #{@album.date}"
  end

  def test_directory_with_spaces_has_them_removed
    path = '/2017-02-23-storm-doris-dismantles-pier at lough mac nean blacklion county cavan/02-img_0039.jpg'
    album = Album.new(path)

    assert album.title == 'Storm Doris Dismantles Pier At Lough Mac Nean Blacklion County Cavan',
           "The album title is wrong -- #{album.title}"
    assert album.filename == '../PhotosOfBlacklion.github.io/_posts/2017/2017-02-23-storm-doris-dismantles-pier-at-lough-mac-nean-blacklion-county-cavan.md',
           "The album filename is wrong -- #{album.filename}"
    assert album.date == '2017-02-23 12:00',
           "The ablbum date is wrong -- #{album.date}"
  end
end
