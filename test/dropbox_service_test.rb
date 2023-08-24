# frozen_string_literal: true

require_relative 'test_helper'

class DropboxServiceTest < CaptainHookTest
  def test_oauth_api
    code = "deadbeef"

    stub_request(:post, "https://api.dropbox.com/oauth2/token")
      .with(body: "code=deadbeef&redirect_uri=https%3A%2F%2Fhook.photosofblacklion.net%2Foauth_callback&grant_type=authorization_code&client_id=&client_secret=deadbeef")
    assert DropboxService.oauth_api(code)
  end
end
