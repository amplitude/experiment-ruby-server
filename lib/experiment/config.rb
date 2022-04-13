module Experiment
  # Configuration
  class Config
    DEFAULT_SERVER_URL = 'https://api.lab.amplitude.com'.freeze
    attr_accessor :debug, :server_url, :fetch_timeout_millis, :fetch_retries, :fetch_retry_backoff_min_millis,
                  :fetch_retry_backoff_max_millis, :fetch_retry_backoff_scalar, :fetch_retry_timeout_millis

    # @param [Boolean] debug Set to true to log some extra information to the console.
    # @param [String] server_url The server endpoint from which to request variants.
    # @param [Integer] fetch_timeout_millis The request timeout, in milliseconds, used when fetching variants
    # triggered by calling start() or setUser().
    # @param [Integer] fetch_retries The number of retries to attempt before failing.
    # @param [Integer] fetch_retry_backoff_min_millis Retry backoff minimum (starting backoff delay) in milliseconds.
    # The minimum backoff is scaled by
    # fetch_retry_backoff_scalar` after each retry failure.
    # @param [Integer] fetch_retry_backoff_max_millis Retry backoff maximum in milliseconds. If the scaled backoff is
    # greater than the max, the max is used for all subsequent retries.
    # @param [Float] fetch_retry_backoff_scalar Scales the minimum backoff exponentially.
    # @param [Integer] fetch_retry_timeout_millis The request timeout for retrying fetch requests.
    def initialize(debug: false, server_url: DEFAULT_SERVER_URL, fetch_timeout_millis: 10_000, fetch_retries: 0,
                   fetch_retry_backoff_min_millis: 500, fetch_retry_backoff_max_millis: 10_000,
                   fetch_retry_backoff_scalar: 1.5, fetch_retry_timeout_millis: 10_000)
      @debug = debug
      @server_url = server_url
      @fetch_timeout_millis = fetch_timeout_millis
      @fetch_retries = fetch_retries
      @fetch_retry_backoff_min_millis = fetch_retry_backoff_min_millis
      @fetch_retry_backoff_max_millis = fetch_retry_backoff_max_millis
      @fetch_retry_backoff_scalar = fetch_retry_backoff_scalar
      @fetch_retry_timeout_millis = fetch_retry_timeout_millis
    end
  end
end
