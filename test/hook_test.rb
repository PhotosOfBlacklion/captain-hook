require_relative "test_helper"
require "dm-sqlite-adapter"
require 'dm-migrations'

DataMapper.setup(:default, "sqlite::memory:")

class Dropbox
  include DataMapper::Resource

  property :id,         Serial
  property :path,       String
  property :processed,  Boolean,  :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
DataMapper.finalize
DataMapper.auto_migrate!

class AlbumTest < CaptainHook::Test
  def test_get_file
    Dropbox.create(:path => '/2017-01-01-new-years/01-img.jpg', :processed => true)
    Dropbox.create(:path => '/2017-01-01-new-years/02-img.jpg')
    hook = Hook.new
    file = hook.get_file
    assert file.path == "/2017-01-01-new-years/01-img.jpg",
      "We picked up a processed file by mistake"
  end
end
