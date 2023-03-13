require 'uri'
require 'logger'

module AmplitudeExperiment
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
      @fetcher = LocalEvaluationFetcher.new(api_key, @config.debug, @config.server_url)
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Locally evaluates flag variants for a user.
    #
    # @param [User] user The user to evaluate
    # @param [String[]] flag_keys The flags to evaluate with the user. If empty, all flags from the flag cache are evaluated
    #
    # @return [Hash[String, Variant]] The evaluated variants
    def evaluate(user, flag_keys = [])
      variants = {}
      flags = @flags_mutex.synchronize do
        @flags
      end
      return variants if flags == nil
      user_str = user.to_json
      @logger.debug("[Experiment] Evaluate: User: #{user_str} - Rules: #{flags}") if @config.debug
      result_json = evaluation(flags, user_str)
      @logger.debug("[Experiment] evaluate - result: #{result_json}") if @config.debug
      result = JSON.parse(result_json)
      filter = flag_keys.length == 0
      result.each do |key, value|
        next if value['isDefaultVariant'] || (filter && flag_keys.include?(key))
        variant_key = value['variant']['key']
        variant_payload = value['variant']['payload']
        variants.store(key, Variant.new(variant_key, variant_payload))
      end
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
