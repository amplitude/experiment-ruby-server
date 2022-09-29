module AmplitudeExperiment
  # LocalEvaluationFetcher
  # Fetch local evaluation mode flag configs from the Experiment API server.
  # These flag configs can be used to perform local evaluation.
  class LocalEvaluationFetcher
    FLAG_CONFIG_TIMEOUT = 5000

    def initialize(api_key, debug, server_url = 'https://api.lab.amplitude.com')
      @api_key = api_key
      @uri = "#{server_url}/sdk/rules?eval_mode=local"
      @debug = debug
      @http =  PersistentHttpClient.get(@uri, { read_timeout: FLAG_CONFIG_TIMEOUT })
    end

    # Fetch local evaluation mode flag configs from the Experiment API server.
    # These flag configs can be used to perform local evaluation.
    #
    # @return [Hash] The flag configs
    def fetch
      # fetch flag_configs
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8',
        'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}"
      }
      request = Net::HTTP::Get.new(@uri, headers)
      response = @http.request(request)
      raise "flagConfigs - received error response: #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPOK)

      flag_configs = parse(response.body)
      @logger.debug("[Experiment] Fetch flag configs: #{request.body}") if @debug
      flag_configs
    end

    private

    def parse(flag_configs_str)
      flag_config_obj = {}
      flag_configs_array = JSON.parse(flag_configs_str)
      flag_configs_array.each do |flag_config|
        flag_config_obj.store(flag_config['flagKey'], flag_config) if flag_config.key?('flagKey')
      end
      flag_config_obj
    end
  end
end
