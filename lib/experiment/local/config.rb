require 'logger'

module AmplitudeExperiment
  module ServerZone
    US = 'US'.freeze
    EU = 'EU'.freeze
  end

  # LocalEvaluationConfig
  class LocalEvaluationConfig
    # Default server url
    DEFAULT_SERVER_URL = 'https://api.lab.amplitude.com'.freeze
    EU_SERVER_URL = 'https://flag.lab.eu.amplitude.com'.freeze
    DEFAULT_LOGDEV = $stdout
    DEFAULT_LOG_LEVEL = Logger::ERROR

    # Set to true to log some extra information to the console.
    # @return [Boolean] the value of debug
    attr_accessor :debug

    # Set the client logger to a user defined [Logger]
    # @return [Logger] the logger instance of the client
    attr_accessor :logger

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
    # @deprecated use exposure_config instead
    # @return [AssignmentConfig] the config instance
    attr_accessor :assignment_config

    # Configuration for automatically tracking exposure events after an evaluation.
    # @return [ExposureConfig] the config instance
    attr_accessor :exposure_config

    # Configuration for downloading cohorts required for flag evaluation
    # @return [CohortSyncConfig] the config instance
    attr_accessor :cohort_sync_config

    # @param [Boolean] debug Set to true to log some extra information to the console.
    # @param [Logger] logger instance to be used for all client logging behavior
    # @param [String] server_url The server endpoint from which to request variants.
    # @param [String] server_zone Location of the Amplitude data center to get flags and cohorts from, US or EU
    # @param [Hash] bootstrap The value of bootstrap.
    # @param [long] flag_config_polling_interval_millis The value of flag config polling interval in million seconds.
    # @param [AssignmentConfig] assignment_config Configuration for automatically tracking assignment events after an evaluation. @deprecated use exposure_config instead
    # @param [ExposureConfig] exposure_config Configuration for automatically tracking exposure events after an evaluation.
    # @param [CohortSyncConfig] cohort_sync_config Configuration for downloading cohorts required for flag evaluation
    def initialize(server_url: DEFAULT_SERVER_URL,
                   server_zone: ServerZone::US,
                   bootstrap: {},
                   flag_config_polling_interval_millis: 30_000,
                   debug: false,
                   logger: nil,
                   assignment_config: nil,
                   exposure_config: nil,
                   cohort_sync_config: nil)
      @logger = logger
      if logger.nil?
        @logger = Logger.new(DEFAULT_LOGDEV)
        @logger.level = debug ? Logger::DEBUG : DEFAULT_LOG_LEVEL
      end
      @server_url = server_url
      @server_zone = server_zone
      @cohort_sync_config = cohort_sync_config
      if server_url == DEFAULT_SERVER_URL && @server_zone == ServerZone::EU
        @server_url = EU_SERVER_URL
        @cohort_sync_config.cohort_server_url = EU_COHORT_SYNC_URL if @cohort_sync_config && @cohort_sync_config.cohort_server_url == DEFAULT_COHORT_SYNC_URL
      end
      @bootstrap = bootstrap
      @flag_config_polling_interval_millis = flag_config_polling_interval_millis
      @assignment_config = assignment_config
      @exposure_config = exposure_config
    end
  end
end
