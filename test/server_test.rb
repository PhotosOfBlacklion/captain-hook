# frozen_string_literal: true

require_relative "test_helper"

class ServerTest < CaptainHookTest

  def app
    POB
  end

  def test_get_root_returns_404_without_parameters
    get "/"

    assert_equal(404, last_response.status, "Expected / to be 404, but got #{last_response.status}")
  end

  def test_get_root_returns_200_with__challenge_parameter
    get "/?challenge=1234"

    assert_equal 200, last_response.status, "Expected /?challenge=1234 to be 200, but got #{last_response.status}"
  end

  def test_get_connect_returns_200
    get "/connect"

    assert_equal 200, last_response.status, "Expected /connect to return 200, but got #{last_response.status}"
    assert_includes last_response.body, "Connect to Dropbox"
  end

  def test_get_oauth_callback_returns_401_on_error
    get "/oauth_callback?error"

    assert_equal 401, last_response.status, "Expected /oauth_callback?error to return 200, but got #{last_response.status}"
  end

  def test_get_oauth_callback_fails_without_expected_code
    get "/oauth_callback"

    assert_equal 500, last_response.status, "Expected /oauth_callback to return 500, but got #{last_response.status}"
  end

  def test_get_oauth_callback_with_code
    json = '{
      "access_token": "sl.AbX9y6Fe3AuH5o66-gmJpR032jwAwQPIVVzWXZNkdzcYT02akC2de219dZi6gxYPVnYPrpvISRSf9lxKWJzYLjtMPH-d9fo_0gXex7X37VIvpty4-G8f4-WX45AcEPfRnJJDwzv-",
      "expires_in": "13220",
      "token_type": "bearer",
      "scope": "account_info.read files.content.read files.content.write files.metadata.read",
      "account_id": "dbid:AAH4f99T0taONIb-OurWxbNQ6ywGRopQngc",
      "uid": "12345"
      }'
    DropboxService.stub :oauth_api, json do
      get "/oauth_callback?code=1234"

      assert_equal(200, last_response.status, "Expected /oauth_callback to return 200, but got #{last_response.status}")
      assert_equal 1, Token.all.count
    end
  end

  def test_login
    get "/login"

    assert_equal 302, last_response.status
    assert_equal "https://www.dropbox.com/oauth2/authorize?response_type=code&client_id=&redirect_uri=http%3A%2F%2Fexample.org%2Foauth_callback", last_response.location
  end

  def test_post_root_returns_400_without_dropbox_signature
    post "/"

    assert_equal 400, last_response.status
  end

  def test_post_root_returns_403_when_dropbox_signature_comparison_fails
    Config.stub :signature, "deadbeef" do
      post "/"

      assert_equal 403, last_response.status
    end
  end

  def test_post_root_returns
    stub_request(:post, "https://api.dropboxapi.com/2/files/list_folder").
      with(
        headers: {
          "Authorization"=>"Bearer deadbeef",
          "Content-Type"=>"application/json",
        }).
        to_return(status: 200, body: '{"entries"=>[]}')

    DB.transaction(rollback: :always, auto_savepoint: true) do
      Token.create(user: "troz", token: "deadbeef")
      Config.stub :signature, "3318b3cd3f70641fe506b85458f368bdef213395221fbfa9585c7aa1c5008663" do
        post "/", JSON.generate(list_folder: { accounts: ["troz"] })

        assert_equal 200, last_response.status
      end
    end
  end
end
