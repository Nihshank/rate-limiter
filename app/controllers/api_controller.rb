class ApiController < ApplicationController
  def index
    render json: { message: "Success", requests_remaining: requests_remaining }
  end

  private

  def requests_remaining
    key = "rate_limit:#{request.headers['X-API-Key']}"
    RateLimiterMiddleware::MAX_REQUESTS - $redis.zcard(key)
  end
end