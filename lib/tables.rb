require 'dm-mysql-adapter'
require 'dotenv'

Dotenv.load

DataMapper.setup(:default, "mysql://root@localhost/hooks")

class Dropbox
  include DataMapper::Resource

  property :id,         Serial
  property :path,       String,   :length => 255
  property :processed,  Boolean,  :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
class Token
  include DataMapper::Resource

  property :id,         Serial
  property :user,       String,   :length => 255
  property :token,      String,   :length => 255
  property :created_at, DateTime
end
DataMapper.finalize
