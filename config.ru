require File.expand_path('../server.rb', __FILE__)
use Rack::ShowExceptions
run POB.new
