# frozen_string_literal: true

module Config
  def self.signature
    @signature ||= ENV["HTTP_X_DROPBOX_SIGNATURE"]
  end

  def self.client_secret
    return "deadbeef" if ENV["APP_ENV"] == "test"
    @app_secret ||= ENV["APP_SECRET"]
  end

  def self.client_id
    @client_id ||= ENV["APP_KEY"]
  end

  def self.database_url
    @database_url ||= ENV["DATABASE_URL"]
  end

  def self.db
    @db ||= Sequel.connect(Config.database_url)
  end
end
