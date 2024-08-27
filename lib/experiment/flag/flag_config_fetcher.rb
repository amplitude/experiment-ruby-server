module AmplitudeExperiment
  # LocalEvaluationFetcher
  # Fetch local evaluation mode flag configs from the Experiment API server.
  # These flag configs can be used to perform local evaluation.
  class LocalEvaluationFetcher
    FLAG_CONFIG_TIMEOUT = 5000

    def initialize(api_key, logger, server_url = 'https://api.lab.amplitude.com')
      @api_key = api_key
      @server_url = server_url
      @logger = logger
    end

    # Fetch local evaluation mode flag configs from the Experiment API server.
    # These flag configs can be used to perform local evaluation.
    #
    # @return [String] The flag configs
    def fetch_v1
      # fetch flag_configs
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8',
        'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}"
      }
      request = Net::HTTP::Get.new("#{@server_url}/sdk/v1/flags", headers)
      http = PersistentHttpClient.get(@server_url, { read_timeout: FLAG_CONFIG_TIMEOUT }, @api_key)
      response = http.request(request)
      raise "flagConfigs - received error response: #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPOK)

      @logger.debug("[Experiment] Fetch flag configs: #{response.body}")
      response.body
    end

    def fetch_v2
      # fetch flag_configs
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8',
        'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}"
      }
      request = Net::HTTP::Get.new("#{@server_url}/sdk/v2/flags?v=0", headers)
      http = PersistentHttpClient.get(@server_url, { read_timeout: FLAG_CONFIG_TIMEOUT }, @api_key)
      response = http.request(request)
      raise "flagConfigs - received error response: #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPOK)

      @logger.debug("[Experiment] Fetch flag configs: #{response.body}")
      JSON.parse(response.body)
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
      request = Net::HTTP::Get.new("#{@server_url}/sdk/rules?eval_mode=local", headers)
      http = PersistentHttpClient.get(@server_url, { read_timeout: FLAG_CONFIG_TIMEOUT }, @api_key)
      response = http.request(request)
      raise "flagConfigs - received error response: #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPOK)

      flag_configs = parse(response.body)
      @logger.debug("[Experiment] Fetch flag configs: #{request.body}")
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
