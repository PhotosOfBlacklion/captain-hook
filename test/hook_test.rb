require_relative "test_helper"

class AlbumTest < CaptainHook::Test
  def test_get_file
    Dropbox.insert(:path => '/2017-01-01-new-years/01-img.jpg', :processed => true)
    Dropbox.insert(:path => '/2017-01-01-new-years/02-img.jpg')
    hook = Hook.new
    file = hook.get_file
    assert file.path == "/2017-01-01-new-years/02-img.jpg",
      "We picked up a processed file by mistake #{file.path}"
  end
end
