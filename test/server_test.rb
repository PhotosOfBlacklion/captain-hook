# frozen_string_literal: true

require_relative 'test_helper'

class ServerTest < CaptainHookTest

  def app
    POB
  end

  def test_get_root_returns_404_without_parameters
    get '/'
    assert last_response.status == 404, "Expected / to be 404, but got #{last_response.status}"
  end

  def test_get_root_returns_200_with__challenge_parameter
    get '/?challenge=1234'
    assert last_response.status == 200, "Expected /?challenge=1234 to be 200, but got #{last_response.status}"
  end

  def test_get_connect_returns_200
    get '/connect'

    assert last_response.status == 200, "Expected /connect to return 200, but got #{last_response.status}"
    assert last_response.body.include?('Connect to Dropbox')
  end

  def test_get_oauth_callback_returns_401_on_error
    get '/oauth_callback?error'

    assert last_response.status == 401, "Expected /oauth_callback?error to return 200, but got #{last_response.status}"
  end

  def test_get_oauth_callback
    get '/oauth_callback'

    assert last_response.status == 500, "Expected /oauth_callback to return 500, but got #{last_response.status}"
  end
end
