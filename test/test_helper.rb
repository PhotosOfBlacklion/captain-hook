require "minitest/autorun"
require "sequel"
require "simplecov"

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/test/'
end

DB = Sequel.connect('sqlite://db/hook_test.db')

require "./lib/album"
require "./lib/hook"
require "./lib/photo"

module CaptainHook
  class Test < MiniTest::Test
  end
end
