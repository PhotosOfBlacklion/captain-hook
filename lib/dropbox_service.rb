# frozen_string_literal: true

class DropboxService
  def self.oauth_api(code)
    body = {
      code: code,
      redirect_uri: url('oauth_callback'),
      grant_type: 'authorization_code',
      client_id: ENV['APP_KEY'],
      client_secret: ENV['APP_SECRET']
    }
    url = 'https://api.dropbox.com/1/oauth2/token'

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = URI.encode_www_form(body)

    http.request(request).body.gsub('=>', ':')
  end
end

