module AmplitudeExperiment
  # LocalEvaluationConfig
  class LocalEvaluationConfig
    # Default server url
    DEFAULT_SERVER_URL = 'https://api.lab.amplitude.com'.freeze
    EU_SERVER_URL = 'https://flag.lab.eu.amplitude.com'.freeze

    # Set to true to log some extra information to the console.
    # @return [Boolean] the value of debug
    attr_accessor :debug

    # The server endpoint from which to request variants.
    # @return [String] the value of server url
    attr_accessor :server_url

    # Location of the Amplitude data center to get flags and cohorts from, US or EU
    # @return [String] the value of server zone
    attr_accessor :server_zone

    # The polling interval for flag configs.
    # @return [long] the value of flag config polling interval in million seconds
    attr_accessor :flag_config_polling_interval_millis

    # Configuration for automatically tracking assignment events after an evaluation.
    # @return [AssignmentConfig] the config instance
    attr_accessor :assignment_config

    # Configuration for downloading cohorts required for flag evaluation
    # @return [CohortSyncConfig] the config instance
    attr_accessor :cohort_sync_config

    # @param [Boolean] debug Set to true to log some extra information to the console.
    # @param [String] server_url The server endpoint from which to request variants.
    # @param [String] server_zone Location of the Amplitude data center to get flags and cohorts from, US or EU
    # @param [Hash] bootstrap The value of bootstrap.
    # @param [long] flag_config_polling_interval_millis The value of flag config polling interval in million seconds.
    # @param [AssignmentConfig] assignment_config Configuration for automatically tracking assignment events after an evaluation.
    # @param [CohortSyncConfig] cohort_sync_config Configuration for downloading cohorts required for flag evaluation
    def initialize(server_url: DEFAULT_SERVER_URL, server_zone: 'us', bootstrap: {},
                   flag_config_polling_interval_millis: 30_000, debug: false, assignment_config: nil,
                   cohort_sync_config: nil)
      @debug = debug || false
      @server_url = server_url
      @server_zone = server_zone.downcase
      @cohort_sync_config = cohort_sync_config
      if server_url == DEFAULT_SERVER_URL && @server_zone == 'eu'
        @server_url = EU_SERVER_URL
        @cohort_sync_config.cohort_server_url = EU_COHORT_SYNC_URL if @cohort_sync_config && @cohort_sync_config.cohort_server_url == DEFAULT_COHORT_SYNC_URL
      end
      @bootstrap = bootstrap
      @flag_config_polling_interval_millis = flag_config_polling_interval_millis
      @assignment_config = assignment_config
    end
  end
end
