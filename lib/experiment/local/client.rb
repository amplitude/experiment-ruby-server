require 'uri'
require 'logger'
require_relative '../../amplitude'

module AmplitudeExperiment
  FLAG_TYPE_MUTUAL_EXCLUSION_GROUP = 'mutual_exclusion_group'.freeze
  # Main client for fetching variant data.
  class LocalEvaluationClient
    # Creates a new Experiment Client instance.
    #
    # @param [String] api_key The environment API Key
    # @param [LocalEvaluationConfig] config The config object

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
      @assignment_service = AssignmentService.new(AmplitudeAnalytics::Amplitude.new(config.assignment_config.api_key, configuration: config.assignment_config), AssignmentFilter.new(config.assignment_config.cache_capacity)) if config&.assignment_config
    end

    # Locally evaluates flag variants for a user.
    #
    # @param [User] user The user to evaluate
    # @param [String[]] flag_keys The flags to evaluate with the user. If empty, all flags from the flag cache are evaluated
    #
    # @return [Hash[String, Variant]] The evaluated variants
    def evaluate(user, flag_keys = [])
      warn 'evaluate is deprecated, please use evaluate_v2 instead.'
      variants = evaluate_v2(user, flag_keys)
      AmplitudeExperiment.filter_default_variants(variants)
    end

    # Locally evaluates flag variants for a user.
    #  This function will only evaluate flags for the keys specified in the flag_keys argument. If flag_keys is
    #  missing or None, all flags are evaluated. This function differs from evaluate as it will return a default
    #  variant object if the flag was evaluated but the user was not assigned (i.e. off).
    #
    # @param [User] user The user to evaluate
    # @param [String[]] flag_keys The flags to evaluate with the user, if empty all flags are evaluated
    # @return [Hash[String, Variant]] The evaluated variants
    def evaluate_v2(user, flag_keys = [])
      flags = @flags_mutex.synchronize do
        @flags
      end
      return {} if flags.nil?

      sorted_flags = AmplitudeExperiment.topological_sort(flags, flag_keys.to_set)
      flags_json = sorted_flags.to_json

      enriched_user = AmplitudeExperiment.user_to_evaluation_context(user)
      user_str = enriched_user.to_json

      @logger.debug("[Experiment] Evaluate: User: #{user_str} - Rules: #{flags}") if @config.debug
      result = evaluation(flags_json, user_str)
      @logger.debug("[Experiment] evaluate - result: #{result}") if @config.debug
      variants = AmplitudeExperiment.evaluation_variants_json_to_variants(result)
      @assignment_service&.track(Assignment.new(user, variants))
      variants
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

    def run
      @is_running = true
      begin
        flags = @fetcher.fetch_v2
        flags_obj = JSON.parse(flags)
        flags_map = flags_obj.each_with_object({}) { |flag, hash| hash[flag['key']] = flag }
        @flags_mutex.synchronize do
          @flags = flags_map
        end
      rescue StandardError => e
        @logger.error("[Experiment] Flag poller - error: #{e.message}")
      end
      @poller_thread = Thread.new do
        sleep(@config.flag_config_polling_interval_millis / 1000.to_f)
        run
      end
    end
  end
end
