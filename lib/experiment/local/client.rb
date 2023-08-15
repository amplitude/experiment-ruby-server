require 'uri'
require 'logger'
require_relative '../../amplitude'

module AmplitudeExperiment
  # Main client for fetching variant data.
  class LocalEvaluationClient
    # Creates a new Experiment Client instance.
    #
    # @param [String] api_key The environment API Key
    # @param [LocalEvaluationConfig] config The config object
    attr_reader :assignment_service

    def initialize(api_key, config = nil)
      require 'experiment/local/evaluation/evaluation'
      @api_key = api_key
      @config = config || LocalEvaluationConfig.new
      @flags = nil
      @flags_mutex = Mutex.new
      @logger = Logger.new($stdout)
      @logger.level = if @config.debug
                        Logger::DEBUG
                      else
                        Logger::INFO
                      end
      @fetcher = LocalEvaluationFetcher.new(api_key, @logger, @config.server_url)
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?

      @assignment_service = nil
      if config&.assignment_config
        amplitude = AmplitudeAnalytics::Amplitude.new(config.assignment_config.api_key, configuration: config.assignment_config.amp_config)
        filter = AssignmentFilter.new(config.assignment_config.cache_capacity)
        @assignment_service = AssignmentService.new(amplitude, filter)
      end
    end

    # Locally evaluates flag variants for a user.
    #
    # @param [User] user The user to evaluate
    # @param [String[]] flag_keys The flags to evaluate with the user. If empty, all flags from the flag cache are evaluated
    #
    # @return [Hash[String, Variant]] The evaluated variants
    def evaluate(user, flag_keys = [])
      flags = @flags_mutex.synchronize do
        @flags
      end
      user_str = user.to_json
      if flags.nil?
        @assignment_service&.track(Assignment.new(user, {}))
        return {}
      end

      @logger.debug("[Experiment] Evaluate: User: #{user_str} - Rules: #{flags}") if @config.debug
      result = evaluation(flags, user_str)
      @logger.debug("[Experiment] evaluate - result: #{result}") if @config.debug
      @assignment_service&.track(Assignment.new(user, result))
      parse_results(result, flag_keys)
    end

    # Fetch initial flag configurations and start polling for updates.
    # You must call this function to begin polling for flag config updates.
    def start
      return if @is_running

      @logger.debug('[Experiment] poller - start') if @debug
      run
    end

    # Stop polling for flag configurations. Close resource like connection pool with client
    def stop
      @poller_thread&.exit
      @is_running = false
      @poller_thread = nil
    end

    private

    def parse_results(result, flag_keys)
      variants = {}
      result.each do |key, value|
        next if value['isDefaultVariant'] || (flag_keys.empty? && flag_keys.include?(key))

        variant_key = value['variant']['key']
        variant_payload = value['variant']['payload']
        variants.store(key, Variant.new(variant_key, variant_payload))
      end
      variants
    end

    def run
      @is_running = true
      flags = @fetcher.fetch_v1
      @flags_mutex.synchronize do
        @flags = flags
      end
      @poller_thread = Thread.new do
        sleep(@config.flag_config_polling_interval_millis / 1000.to_f)
        run
      end
    end
  end
end
