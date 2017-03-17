require 'dm-mysql-adapter'
require 'dotenv'

Dotenv.load

DataMapper.setup(:default, "mysql://hook:#{ENV['MYSQL_PASSWORD']}@localhost/hooks")

class Dropbox
  include DataMapper::Resource

  property :id,         Serial
  property :path,       String
  property :processed,  Boolean,  :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
class Token
  include DataMapper::Resource

  property :id,         Serial
  property :user,       String
  property :token,      String
  property :created_at, DateTime
end
DataMapper.finalize
