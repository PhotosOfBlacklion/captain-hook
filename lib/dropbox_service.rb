# frozen_string_literal: true

class DropboxService
  def self.oauth_api(code)
    body = {
      code: code,
      redirect_uri: "https://hook.photosofblacklion.net/oauth_callback",
      grant_type: 'authorization_code',
      client_id: Config.client_id,
      client_secret: Config.client_secret
    }
    url = 'https://api.dropbox.com/oauth2/token'

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = URI.encode_www_form(body)

    http.request(request).body.gsub('=>', ':')
  end
end

