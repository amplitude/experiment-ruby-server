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
      @engine = Evaluation::Engine.new

      @assignment_service = nil
      @assignment_service = AssignmentService.new(AmplitudeAnalytics::Amplitude.new(config.assignment_config.api_key, configuration: config.assignment_config), AssignmentFilter.new(config.assignment_config.cache_capacity)) if config&.assignment_config

      @cohort_storage = InMemoryCohortStorage.new
      @flag_config_storage = InMemoryFlagConfigStorage.new
      @flag_config_fetcher = LocalEvaluationFetcher.new(@api_key, @logger, @config.server_url)
      @cohort_loader = nil
      unless @config.cohort_sync_config.nil?
        @cohort_download_api = DirectCohortDownloadApi.new(@config.cohort_sync_config.api_key,
                                                           @config.cohort_sync_config.secret_key,
                                                           @config.cohort_sync_config.max_cohort_size,
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
    # @deprecated Please use {evaluate_v2} instead
    def evaluate(user, flag_keys = [])
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
      flags = @flag_config_storage.flag_configs
      return {} if flags.nil?

      sorted_flags = TopologicalSort.sort(flags, flag_keys)
      required_cohorts_in_storage(sorted_flags)
      user = enrich_user_with_cohorts(user, flags) if @config.cohort_sync_config
      context = AmplitudeExperiment.user_to_evaluation_context(user)

      @logger.debug("[Experiment] Evaluate: User: #{context} - Rules: #{flags}") if @config.debug
      result = @engine.evaluate(context, sorted_flags)
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
      @is_running = false
      @deployment_runner.stop
    end

    private

    def required_cohorts_in_storage(flag_configs)
      stored_cohort_ids = @cohort_storage.cohort_ids

      flag_configs.each do |flag|
        flag_cohort_ids = AmplitudeExperiment.get_all_cohort_ids_from_flag(flag)
        missing_cohorts = flag_cohort_ids - stored_cohort_ids

        next unless missing_cohorts.any?

        # Convert cohort IDs to a comma-separated string
        cohort_ids_str = "[#{flag_cohort_ids.map(&:to_s).join(', ')}]"
        missing_cohorts_str = "[#{missing_cohorts.map(&:to_s).join(', ')}]"

        message = if @config.cohort_sync_config
                    "Evaluating flag #{flag.key} dependent on cohorts #{cohort_ids_str} without #{missing_cohorts_str} in storage"
                  else
                    "Evaluating flag #{flag.key} dependent on cohorts #{cohort_ids_str} without cohort syncing configured"
                  end

        @logger.warn(message)
      end
    end

    def enrich_user_with_cohorts(user, flag_configs)
      grouped_cohort_ids = AmplitudeExperiment.get_grouped_cohort_ids_from_flags(flag_configs)

      if grouped_cohort_ids.key?(USER_GROUP_TYPE)
        user_cohort_ids = grouped_cohort_ids[USER_GROUP_TYPE]
        user.cohort_ids = Array(@cohort_storage.get_cohorts_for_user(user.user_id, user_cohort_ids)) if user_cohort_ids && user.user_id
      end

      user.groups&.each do |group_type, group_names|
        group_name = group_names.first if group_names
        next unless group_name

        cohort_ids = grouped_cohort_ids[group_type] || []
        next if cohort_ids.empty?

        user.add_group_cohort_ids(
          group_type,
          group_name,
          Array(@cohort_storage.get_cohorts_for_group(group_type, group_name, cohort_ids))
        )
      end
      user
    end
  end
end
