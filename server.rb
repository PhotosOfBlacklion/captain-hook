#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'
require 'dotenv'
require 'net/http'
require 'uri'
require 'logger'
require File.expand_path('../lib/tables', __FILE__)

set :bind, '0.0.0.0'
Dotenv.load

logger = Logger.new('captain-hook.log', 'daily')
logger.level = Logger::INFO
logger.datetime_format = '%Y-%m-%d %H:%M:%S'

helpers do
  def valid_dropbox_request?(message)
    digest = OpenSSL::Digest::SHA256.new
    signature = OpenSSL::HMAC.hexdigest(digest, ENV['APP_SECRET'], message)
    env['HTTP_X_DROPBOX_SIGNATURE'] == signature
  end
end

not_found do
  '404: Not Found'
end

get '/' do
  not_found unless params['challenge']
  return params['challenge']
end

post '/' do
  halt 400, 'Missing X-Dropbox-Signature' unless env['HTTP_X_DROPBOX_SIGNATURE']
  halt 403 unless valid_dropbox_request?(request.body.read)

  request.body.rewind
  req_body = JSON.parse(request.body.read)

  account = req_body['list_folder']['accounts'].first
  token = Token.first(:user => account)

  logger.info('Dropbox webhook fired')
  body = { path: '', recursive: true }
  url = 'https://api.dropboxapi.com/2/files/list_folder'
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = body.to_json

  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{token}"

  response = http.request(request)

  resp_body = response.body
  json = JSON.parse(resp_body.gsub('=>', ':'))
  json['entries'].each do |entries|
    if entries['.tag'] == 'file' && entries['path_lower'][-3..-1] == 'jpg'
      file = Dropbox.create(
        :path       => entries['path_lower'],
        :created_at => Time.now,
        :updated_at => Time.now
      )
      logger.info("#{entries['path_lower']} added to the database")
    end
  end unless json['entries'].empty?

  logger.info('Forking out to process things')
  fork do
    exec './out.rb'
  end
  logger.info('Dropbox webhook finished')
  ''
end
