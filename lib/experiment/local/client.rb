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
    def evaluate(user = User.new, flag_keys = [])
      flag_configs = []
      if flag_keys.empty?
        @cache.get_all.each do |key, value|
          flag_configs.push(value)
        end
      else
        flag_configs = get_flag_configs(flag_keys)
      end
      #flag_configs_str = JSeON.generate(flag_configs.to_json)
      #user_str = JSON.generate(user.to_json)
      #rulesJson ='[{"allUsersTargetingConfig":{"allocations":[{"percentage":0,"weights":{"array-payload":0,"control":0,"object-payload":0}}],"bucketingKey":"device_id","conditions":[],"name":"default-segment"},"bucketingKey":"device_id","bucketingSalt":"6jLqNjj5","customSegmentTargetingConfigs":[{"allocations":[{"percentage":9900,"weights":{"array-payload":0,"boolean-payload":0,"control":1,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"user_id","conditions":[{"op":"IS","prop":"gp:bucket","values":["user_id"]}],"name":"Bucket by User ID"},{"allocations":[{"percentage":9900,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":1}}],"bucketingKey":"device_id","conditions":[{"op":"IS","prop":"gp:bucket","values":["device_id"]}],"name":"Bucket by Device ID"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":1,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"IS","prop":"gp:test is","values":["string","true","1312.1"]},{"op":"IS_NOT","prop":"gp:test is not","values":["string","true","1312.1"]}],"name":"Test IS & IS NOT"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":1,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"CONTAINS","prop":"gp:test contains","values":["@amplitude.com"]},{"op":"DOES_NOT_CONTAIN","prop":"gp:test does not contain","values":["asdf"]}],"name":"Test CONTAINS & DOES_NOT_CONTAIN"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":1,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"GREATER_THAN","prop":"gp:test greater","values":["1.2.3"]},{"op":"GREATER_THAN_EQUALS","prop":"gp:test greater or equal","values":["1.2.3"]},{"op":"LESS_THAN","prop":"gp:test less","values":["1.2.3"]},{"op":"LESS_THAN_EQUALS","prop":"gp:test less or equal","values":["1.2.3"]}],"name":"Test GREATER & GREATER OR EQUAL & LESS & LESS OR EQUAL"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":1,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"SET_CONTAINS","prop":"gp:test set contains","values":["asdf"]}],"name":"Test SET_CONTAINS (not supported)"}],"defaultValue":"off","enabled":true,"evalMode":"LOCAL","flagKey":"sdk-local-evaluation-unit-test","flagName":"sdk-local-evaluation-unit-test","flagVersion":33,"globalHoldbackBucketingKey":"amplitude_id","globalHoldbackPct":0,"globalHoldbackSalt":null,"mutualExclusionConfig":null,"type":"RELEASE","useStickyBucketing":false,"userProperty":"[Experiment] sdk-local-evaluation-unit-test","variants":[{"key":"control","payload":null},{"key":"treatment","payload":null},{"key":"string-payload","payload":"string"},{"key":"number-payload","payload":1312.1},{"key":"boolean-payload","payload":true},{"key":"object-payload","payload":{"array":[1,2,3],"boolean":true,"number":2,"object":{"k":"v"},"string":"value"}},{"key":"array-payload","payload":[1,2,3,"4",true,{"k":"v"},[1,2,3]]},{"key":"null-payload","payload":null}],"variantsExclusions":null,"variantsInclusions":{"array-payload":["array-payload"],"boolean-payload":["boolean-payload"],"control":["control"],"null-payload":["null-payload"],"number-payload":["number-payload"],"object-payload":["object-payload"],"string-payload":["string-payload"],"treatment":["treatment"]}}]'
      #"[{\"allUsersTargetingConfig\":{\"allocations\":[{\"percentage\":10000,\"weights\":{\"on\":1}}],\"bucketingKey\":\"device_id\",\"conditions\":[],\"name\":\"default-segment\"},\"bucketingKey\":\"device_id\",\"bucketingSalt\":\"52vuIAwB\",\"customSegmentTargetingConfigs\":[],\"defaultValue\":\"off\",\"enabled\":true,\"evalMode\":\"LOCAL\",\"flagKey\":\"asdf-1\",\"flagName\":\"asdf\",\"flagVersion\":7,\"globalHoldbackBucketingKey\":\"amplitude_id\",\"globalHoldbackPct\":0,\"globalHoldbackSalt\":null,\"mutualExclusionConfig\":null,\"type\":\"RELEASE\",\"useStickyBucketing\":false,\"userProperty\":\"[Experiment] asdf-1\",\"variants\":[{\"key\":\"on\",\"payload\":null}],\"variantsExclusions\":null,\"variantsInclusions\":{}}]"
      #userJson = '{"user_id":"test_user"}'
      #puts flag_configs.to_json.inspect.gsub(/\\/, '')
      #puts user.to_json.inspect
      flag_configs_str = flag_configs.to_json.inspect.gsub(/\\/, '')[1..].chop!
      user_str = user.to_json.inspect.gsub(/\\/, '')[1..].chop!
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
      return @cache.get_all if flag_keys.empty?

      flag_configs = []
      flag_keys.each do |key|
        flag_config = @cache.get(key)
        flag_configs.push(flag_config) if flag_config
      end
      flag_configs
    end

  end
end
