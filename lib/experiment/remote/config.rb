module AmplitudeExperiment
  # Configuration
  class RemoteEvaluationConfig
    # Default server url
    DEFAULT_SERVER_URL = 'https://api.lab.amplitude.com'.freeze

    # Set to true to log some extra information to the console.
    # @return [Boolean] the value of debug
    attr_accessor :debug

    # The server endpoint from which to request variants.
    # @return [Boolean] the value of server url
    attr_accessor :server_url

    # The request connection open timeout, in milliseconds, used when fetching variants triggered by calling start() or setUser().
    # @return [Integer] the value of connect_timeout_millis
    attr_accessor :connect_timeout_millis

    # The request timeout, in milliseconds, used when fetching variants triggered by calling start() or setUser().
    # @return [Integer] the value of fetch_timeout_millis
    attr_accessor :fetch_timeout_millis

    # The number of retries to attempt before failing.
    # @return [Integer] the value of fetch_retries
    attr_accessor :fetch_retries

    # Retry backoff minimum (starting backoff delay) in milliseconds. The minimum backoff is scaled
    #  by `fetch_retry_backoff_scalar` after each retry failure.
    # @return [Integer] the value of fetch_retry_backoff_min_millis
    attr_accessor :fetch_retry_backoff_min_millis

    # Retry backoff maximum in milliseconds. If the scaled backoff is greater than the max,
    #   the max is used for all subsequent retries.
    # @return [Integer] the value of fetch_retry_backoff_max_millis
    attr_accessor :fetch_retry_backoff_max_millis

    # Scales the minimum backoff exponentially.
    # @return [Float] the value of fetch_retry_backoff_scalar
    attr_accessor :fetch_retry_backoff_scalar

    # The request timeout for retrying fetch requests.
    # @return [Integer] the value of fetch_retry_timeout_millis
    attr_accessor :fetch_retry_timeout_millis

    # @param [Boolean] debug Set to true to log some extra information to the console.
    # @param [String] server_url The server endpoint from which to request variants.
    # @param [Integer] connect_timeout_millis The request connection open timeout, in milliseconds, used when
    #  fetching variants triggered by calling start() or setUser().
    # @param [Integer] fetch_timeout_millis The request timeout, in milliseconds, used when fetching variants
    #  triggered by calling start() or setUser().
    # @param [Integer] fetch_retries The number of retries to attempt before failing.
    # @param [Integer] fetch_retry_backoff_min_millis Retry backoff minimum (starting backoff delay) in milliseconds.
    #  The minimum backoff is scaled by `fetch_retry_backoff_scalar` after each retry failure.
    # @param [Integer] fetch_retry_backoff_max_millis Retry backoff maximum in milliseconds. If the scaled backoff is
    #  greater than the max, the max is used for all subsequent retries.
    # @param [Float] fetch_retry_backoff_scalar Scales the minimum backoff exponentially.
    # @param [Integer] fetch_retry_timeout_millis The request timeout for retrying fetch requests.
    def initialize(debug: false, server_url: DEFAULT_SERVER_URL, connect_timeout_millis: 60_000, fetch_timeout_millis: 10_000, fetch_retries: 0,
                   fetch_retry_backoff_min_millis: 500, fetch_retry_backoff_max_millis: 10_000,
                   fetch_retry_backoff_scalar: 1.5, fetch_retry_timeout_millis: 10_000)
      @debug = debug
      @server_url = server_url
      @connect_timeout_millis = connect_timeout_millis
      @fetch_timeout_millis = fetch_timeout_millis
      @fetch_retries = fetch_retries
      @fetch_retry_backoff_min_millis = fetch_retry_backoff_min_millis
      @fetch_retry_backoff_max_millis = fetch_retry_backoff_max_millis
      @fetch_retry_backoff_scalar = fetch_retry_backoff_scalar
      @fetch_retry_timeout_millis = fetch_retry_timeout_millis
    end
  end
end
