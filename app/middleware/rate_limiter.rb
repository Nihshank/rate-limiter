class RateLimiterMiddleware
  WINDOW_SIZE = 60  # seconds
  MAX_REQUESTS = 10 # requests per window

  def initialize(app)
    @app = app
  end

  def call(env)
    api_key = env["HTTP_X_API_KEY"]

    if api_key.nil?
      return [ 401, { "Content-Type" => "application/json" }, [ '{"error": "Missing API key"}' ] ]
    end

    if rate_limited?(api_key)
      return [ 429, { "Content-Type" => "application/json" }, [ '{"error": "Rate limit exceeded"}' ] ]
    end

    @app.call(env)
  end

  private

  def rate_limited?(api_key)
    key = "rate_limit:#{api_key}"
    now = Time.now.to_f
    window_start = now - WINDOW_SIZE

    $redis.multi do |pipeline|
      pipeline.zremrangebyscore(key, 0, window_start)
      pipeline.zadd(key, now, now.to_s)
      pipeline.expire(key, WINDOW_SIZE)
    end

    request_count = $redis.zcard(key)
    request_count > MAX_REQUESTS
  end
end
