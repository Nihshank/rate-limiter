require "test_helper"
require "mock_redis"

class RateLimiterMiddlewareTest < ActiveSupport::TestCase
  def setup
    @app = ->(env) { [ 200, {}, [ "OK" ] ] }
    @middleware = RateLimiterMiddleware.new(@app)
    $redis = MockRedis.new
  end

  test "allows request with valid API key" do
    env = { "HTTP_X_API_KEY" => "testkey" }
    status, _, _ = @middleware.call(env)
    assert_equal 200, status
  end

  test "blocks request without API key" do
    env = {}
    status, _, _ = @middleware.call(env)
    assert_equal 401, status
  end

  test "blocks request after exceeding rate limit" do
    env = { "HTTP_X_API_KEY" => "testkey" }
    RateLimiterMiddleware::MAX_REQUESTS.times { @middleware.call(env) }
    status, _, _ = @middleware.call(env)
    assert_equal 429, status
  end
end
