require_relative "test_helper"

class PhotoTest < CaptainHook::Test
  def setup
    path = "/2017-01-17-mike-test/img-01.jpg"
    @photo = Photo.new(path)
  end

  def test_s3_path
    assert @photo.s3_path == "2017/01/mike-test/img-01.jpg", "The s3 path is wrong"
  end
end
