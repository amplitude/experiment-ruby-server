require 'uri'
require 'logger'
require_relative '../../amplitude'

module AmplitudeExperiment
  FLAG_TYPE_MUTUAL_EXCLUSION_GROUP = 'mutual-exclusion-group'.freeze
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
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?

      @assignment_service = nil
      @assignment_service = AssignmentService.new(AmplitudeAnalytics::Amplitude.new(config.assignment_config.api_key, configuration: config.assignment_config), AssignmentFilter.new(config.assignment_config.cache_capacity)) if config&.assignment_config

      @cohort_storage = InMemoryCohortStorage.new
      @flag_config_storage = InMemoryFlagConfigStorage.new
      @flag_config_fetcher = LocalEvaluationFetcher.new(@api_key, @logger, @config.server_url)
      @cohort_loader = nil
      if @config.cohort_sync_config != nil
        @cohort_download_api = DirectCohortDownloadApi.new(@config.cohort_sync_config.api_key,
                                                           @config.cohort_sync_config.secret_key,
                                                           @config.cohort_sync_config.max_cohort_size,
                                                           @config.cohort_sync_config.cohort_request_delay_millis,
                                                           @config.cohort_sync_config.cohort_server_url,
                                                           @logger)
        @cohort_loader = CohortLoader.new(@cohort_download_api, @cohort_storage)
      end
      @deployment_runner = DeploymentRunner.new(@config, @flag_config_fetcher, @flag_config_storage, @cohort_storage, @logger, @cohort_loader)

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
      result = evaluation(flags, user_str)
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
      @deployment_runner.start
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
      end
    end

    def enrich_user(user, flag_configs)
      v = flag_configs.values
      grouped_cohort_ids = AmplitudeExperiment.get_grouped_cohort_ids_from_flags(flag_configs)

      if grouped_cohort_ids.key?(USER_GROUP_TYPE)
        user_cohort_ids = grouped_cohort_ids[USER_GROUP_TYPE]
        if user_cohort_ids && user.user_id
          user.cohort_ids = @cohort_storage.get_cohorts_for_user(user.user_id, user_cohort_ids)
        end
      end

      if user.groups
        user.groups.each do |group_type, group_names|
          group_name = group_names.first if group_names
          next unless group_name

          cohort_ids = grouped_cohort_ids[group_type] || []
          next if cohort_ids.empty?

          user.add_group_cohort_ids(
            group_type,
            group_name,
            @cohort_storage.get_cohorts_for_group(group_type, group_name, cohort_ids)
          )
        end
      end

      user
    end
  end
end
