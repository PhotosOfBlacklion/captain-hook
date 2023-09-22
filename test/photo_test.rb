# frozen_string_literal: true

require_relative "test_helper"

class PhotoTest < CaptainHookTest
  def setup
    path = "/2017-01-17-mike-test/img-01.jpg"
    @photo = Photo.new(path)
  end

  def test_s3_path
    assert_equal("2017/01/mike-test/img-01.jpg", @photo.s3_path, "The s3 path is wrong")
  end

  def test_original
    assert_equal("/2017/01/mike-test/img-01.jpg", @photo.original, "The photo original path is wrong -- #{@photo.original}")
  end

  def test_thumbnail
    assert_equal("/t/2017/01/mike-test/img-01.jpg", @photo.thumbnail, "The photo thumbnail path is wrong -- #{@photo.thumbnail}")
  end

  def test_title
    assert_equal("img-01.jpg", @photo.title, "The photo title path is wrong -- #{@photo.title}")
  end
end
