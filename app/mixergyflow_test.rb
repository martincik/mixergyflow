require 'mixergyflow'
require 'test/unit'
require 'rack/test'

set :environment, :test

class MixergyflowTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_it_returns_list_of_inteviews
    get '/admin'
    assert last_response.ok?
    assert_not_nil last_response.body
  end

end