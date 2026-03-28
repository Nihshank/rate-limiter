# Rate Limiter

A distributed rate limiter built as Rack middleware in Ruby on Rails, backed by Redis.

## How It Works

Each incoming request is identified by its `X-API-Key` header. The middleware uses a **sliding window algorithm** to track request timestamps in a Redis sorted set — allowing a configurable number of requests per time window, and blocking clients that exceed the limit with a `429 Too Many Requests` response.

Unlike a fixed window approach, the sliding window ensures limits are enforced continuously rather than resetting all at once, preventing burst traffic at window boundaries.

## Why Redis

Redis acts as a shared, atomic data store across all Rails processes. This makes the rate limiter truly distributed — multiple server instances all read and write to the same counters, ensuring consistent enforcement regardless of which process handles the request.

## Tech Stack

- **Ruby on Rails** — API server
- **Redis** — distributed request tracking
- **Rack** — middleware layer, intercepts requests before the Rails router

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Returns success and remaining requests |
| GET | `/up` | Health check |

## Configuration

In `app/middleware/rate_limiter_middleware.rb`:
```ruby
WINDOW_SIZE = 60   # seconds
MAX_REQUESTS = 10  # requests per window
```

## Running Locally
```bash
# Install dependencies
bundle install

# Start Redis
redis-server

# Start Rails
rails server
```

## Testing
```bash
# Run tests
bundle exec rails test

# Lint
bundle exec rubocop -a
```

## Example
```bash
# Successful request
curl -H "X-API-Key: mykey" http://localhost:3000
# => {"message":"Success","requests_remaining":9}

# After exceeding limit
curl -H "X-API-Key: mykey" http://localhost:3000
# => {"error":"Rate limit exceeded"}

# Missing API key
curl http://localhost:3000
# => {"error":"Missing API key"}
```