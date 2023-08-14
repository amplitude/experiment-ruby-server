module AmplitudeExperiment
  # LocalEvaluationConfig
  class LocalEvaluationConfig
    # Default server url
    DEFAULT_SERVER_URL = 'https://api.lab.amplitude.com'.freeze

    # Set to true to log some extra information to the console.
    # @return [Boolean] the value of debug
    attr_accessor :debug

    # The server endpoint from which to request variants.
    # @return [String] the value of server url
    attr_accessor :server_url

    # The polling interval for flag configs.
    # @return [long] the value of flag config polling interval in million seconds
    attr_accessor :flag_config_polling_interval_millis

    #TODO: description
    attr_accessor :assignment_config

    # @param [Boolean] debug Set to true to log some extra information to the console.
    # @param [String] server_url The server endpoint from which to request variants.
    # @param [Hash] bootstrap The value of bootstrap.
    # @param [long] flag_config_polling_interval_millis The value of flag config polling interval in million seconds.
    def initialize(server_url = DEFAULT_SERVER_URL, bootstrap = {},
                   flag_config_polling_interval_millis = 30_000, debug = false, assignment_config: nil)
      @debug = debug || false
      @server_url = server_url
      @bootstrap = bootstrap
      @flag_config_polling_interval_millis = flag_config_polling_interval_millis
      @assignment_config = assignment_config
    end
  end
end
