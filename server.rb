#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'json'
require 'dotenv'
require 'net/http'
require 'uri'
require 'logger'

require_relative 'lib/config'
require_relative 'lib/dropbox_service'
require_relative 'lib/models/token'

class POB < Sinatra::Base
  set :bind, '0.0.0.0'
  Dotenv.load

  @db = Sequel.connect(ENV['DATABASE_URL'])

  logger = Logger.new('./logs/server.log', 'daily')
  logger.level = Logger::INFO
  logger.datetime_format = '%Y-%m-%d %H:%M:%S'

  helpers do
    def valid_dropbox_request?(message)
      digest = OpenSSL::Digest.new('SHA256')
      signature = OpenSSL::HMAC.hexdigest(digest, Config.client_secret, message)
      Config.signature == signature
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
    halt 400, 'Missing X-Dropbox-Signature' unless Config.signature
    halt 403 unless valid_dropbox_request?(request.body.read)

    request.body.rewind
    req_body = JSON.parse(request.body.read)

    account = req_body['list_folder']['accounts'].first
    token = Token.first(user: account).token

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
    unless json['entries'].empty?
      json['entries'].each do |entries|
        next unless entries['.tag'] == 'file' && entries['path_lower'][-3..-1] == 'jpg'

        file = Dropbox.first_or_create(
          { path: entries['path_lower'] },
          { user: account,
            created_at: Time.now,
            updated_at: Time.now }
        )
        logger.info("#{entries['path_lower']} added to the database")
      end
    end

    logger.info('Forking out to process things')
    pid = fork { exec './out.rb' }
    Process.detach(pid)
    logger.info('Dropbox webhook finished')
    ''
  end

  get '/connect' do
    erb :connect
  end

  get '/login' do
    params = {
      response_type: 'code',
      client_id: Config.client_id,
      redirect_uri: url('oauth_callback')
    }
    query = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join '&'
    redirect "https://www.dropbox.com/oauth2/authorize?#{query}"
  end

  get '/oauth_callback' do
    if params.key? 'error'
      # uh oh
      halt 401
    end

    halt 500 unless params.key? 'code'

    code = params['code']

    # call dropbox oauth API
    response = JSON.parse(DropboxService.oauth_api(code))
    user  = response["account_id"]
    token = response["access_token"]

    Token.find_or_create(user: user) { |t|
      t.token = token
    }
    erb :connected
  end
end
