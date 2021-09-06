# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'sequel'

DB = Sequel.connect('sqlite://db/hook_test.db')

require_relative '../lib/album'
require_relative '../lib/hook'
require_relative '../lib/photo'
require_relative '../server'

class CaptainHookTest < MiniTest::Test
  include Rack::Test::Methods

  def teardown
    [:tokens].each{|x| DB.from(x).truncate}
  end
end
