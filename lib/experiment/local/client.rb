require 'uri'
require 'logger'
require 'experiment/local/evaluation/evaluation'

module AmplitudeExperiment
  # Main client for fetching variant data.
  class LocalEvaluationClient
    # Creates a new Experiment Client instance.
    #
    # @param [String] api_key The environment API Key
    # @param [LocalEvaluationConfig] config The config object
    def initialize(api_key, config = nil)
      @api_key = api_key
      @config = config || LocalEvaluationConfig.new
      @cache = InMemoryFlagConfigCache.new(@config.bootstrap)
      @logger = Logger.new($stdout)
      @logger.level = if @config.debug
                        Logger::DEBUG
                      else
                        Logger::INFO
                      end
      endpoint = "#{@config.server_url}/sdk/vardata"
      @uri = URI(endpoint)
      @fetcher = LocalEvaluationFetcher.new(api_key, @config.debug)
      @poller = FlagConfigPoller.new(@fetcher, @cache, @config.debug)

      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Locally evaluates flag variants for a user.
    #
    # @param [User] user The user to evaluate
    # @param [String[]] flag_keys The flags to evaluate with the user. If empty, all flags from the flag cache are evaluated
    #
    # @return [Variants] The evaluated variants
    def evaluate(user, flag_keys = [])
      flag_configs = []
      if flag_keys.empty?
        @cache.cache.each do |_, value|
          flag_configs.push(value)
        end
      else
        flag_configs = get_flag_configs(flag_keys)
      end
      flag_configs_str = flag_configs.to_json
      user_str = user.to_json
      @logger.debug("[Experiment] Evaluate: User: #{user_str} - Rules: #{flag_configs_str}") if @config.debug
      variants = evaluation(flag_configs_str, user_str)
      @logger.debug(`[Experiment] evaluate - result: #{variants}`) if @config.debug
      variants
    end

    # Fetch initial flag configurations and start polling for updates.
    # You must call this function to begin polling for flag config updates.
    def start
      @poller.start
    end

    # Stop polling for flag configurations. Close resource like connection pool with client
    def stop
      @poller.stop
    end

    private

    def get_flag_configs(flag_keys = [])
      return @cache.cache if flag_keys.empty?

      flag_configs = []
      flag_keys.each do |key|
        flag_config = @cache.get(key)
        flag_configs.push(flag_config) if flag_config
      end
      flag_configs
    end
  end
end
