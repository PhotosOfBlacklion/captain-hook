# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'sequel'

DB = Sequel.connect('sqlite://db/hook_test.db')

require './lib/album'
require './lib/hook'
require './lib/photo'
require './server'

class CaptainHookTest < MiniTest::Test
  include Rack::Test::Methods
end
