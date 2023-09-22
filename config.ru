# frozen_string_literal: true

require File.expand_path("server.rb", __dir__)
use Rack::ShowExceptions
run POB.new
