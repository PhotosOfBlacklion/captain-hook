# frozen_string_literal: true

require_relative 'test_helper'

class PhotoTest < CaptainHookTest
  def setup
    path = '/2017-01-17-mike-test/img-01.jpg'
    @photo = Photo.new(path)
  end

  def test_s3_path
    assert @photo.s3_path == '2017/01/mike-test/img-01.jpg',
           'The s3 path is wrong'
  end

  def test_original
    assert @photo.original == '/2017/01/mike-test/img-01.jpg',
           "The photo original path is wrong -- #{@photo.original}"
  end

  def test_thumbnail
    assert @photo.thumbnail == '/t/2017/01/mike-test/img-01.jpg',
           "The photo thumbnail path is wrong -- #{@photo.thumbnail}"
  end

  def test_title
    assert @photo.title == 'img-01.jpg',
           "The photo title path is wrong -- #{@photo.title}"
  end
end
