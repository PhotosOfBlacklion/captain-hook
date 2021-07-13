require "minitest/autorun"
require "sequel"

DB = Sequel.connect('sqlite://db/hook_test.db')

require "./lib/album"
require "./lib/hook"
require "./lib/photo"

module CaptainHook
  class Test < MiniTest::Test
  end
end
