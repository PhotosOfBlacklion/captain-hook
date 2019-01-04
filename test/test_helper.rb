if ENV['COVERAGE']
  require "simplecov"

  SimpleCov.start do
    add_filter 'test'
    add_filter 'vendor'
  end
end

require "minitest/autorun"
require "./lib/album"
require "./lib/hook"
require "./lib/photo"

module CaptainHook
  class Test < MiniTest::Test
  end
end
