require 'net/http'
require 'json'
require 'uri'
require 'logger'

module AmplitudeExperiment
  # Main client for fetching variant data.
  class RemoteEvaluationClient
    # Creates a new Experiment Client instance.
    #
    # @param [String] api_key The environment API Key
    # @param [Config] config
    def initialize(api_key, config = nil)
      @api_key = api_key
      @config = config || RemoteEvaluationConfig.new
      @logger = Logger.new($stdout)
      @logger.level = if @config.debug
                        Logger::DEBUG
                      else
                        Logger::INFO
                      end
      endpoint = "#{@config.server_url}/sdk/vardata"
      @uri = URI(endpoint)
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Synchronously fetch user variants for the given flag keys.
    # If flag key is not provided, all variants will be returned.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @param [array] flag_keys
    # @return [Hash] Variants Hash
    def fetch(user, flag_keys = [])
      fetch_internal(user, flag_keys)
    rescue StandardError => e
      @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
      {}
    end

    # Asynchronously fetch user variants for the given flag keys.
    # If flag keys are not provided, all variants will be returned.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @param [array] flag_keys
    # @yield [User, Hash] callback block takes user object and variants hash
    def fetch_async(user, flag_keys = [], &callback)
      Thread.new do
        variants = fetch_internal(user, flag_keys)
        yield(user, variants) unless callback.nil?
        variants
      rescue StandardError => e
        @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
        yield(user, {}) unless callback.nil?
        {}
      end
    end

    private

    # @param [User] user
    # @param [array] flag_keys
    def fetch_internal(user, flag_keys)
      @logger.debug("[Experiment] Fetching variants for user: #{user.as_json}")
      do_fetch(user, flag_keys, @config.fetch_timeout_millis)
    rescue StandardError => e
      @logger.error("[Experiment] Fetch failed: #{e.message}")
      begin
        return retry_fetch(user, flag_keys)
      rescue StandardError => err
        @logger.error("[Experiment] Retry Fetch failed: #{err.message}")
      end
      throw e
    end

    # @param [User] user
    # @param [array] flag_keys
    def retry_fetch(user, flag_keys)
      return {} if @config.fetch_retries.zero?

      @logger.debug('[Experiment] Retrying fetch')
      delay_millis = @config.fetch_retry_backoff_min_millis
      err = nil
      @config.fetch_retries.times do
        sleep(delay_millis.to_f / 1000.0)
        begin
          return do_fetch(user, flag_keys, @config.fetch_retry_timeout_millis)
        rescue StandardError => e
          @logger.error("[Experiment] Retry failed: #{e.message}")
          err = e
        end
        delay_millis = [delay_millis * @config.fetch_retry_backoff_scalar, @config.fetch_retry_backoff_max_millis].min
      end
      throw err unless err.nil?
    end

    # @param [User] user
    # @param [array] flag_keys
    # @param [Integer] timeout_millis
    def do_fetch(user, flag_keys, timeout_millis)
      start_time = Time.now
      user_context = add_context(user)
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8'
      }
      headers['X-Amp-Exp-Flag-Keys'] = Base64.strict_encode64(flag_keys.to_json) unless flag_keys.empty?
      puts headers['X-Amp-Exp-Flag-Keys']
      read_timeout = timeout_millis.to_f / 1000 if (timeout_millis.to_f / 1000) > 0
      http = PersistentHttpClient.get(@uri, { read_timeout: read_timeout }, @api_key)
      request = Net::HTTP::Post.new(@uri, headers)
      request.body = user_context.to_json
      @logger.warn("[Experiment] encoded user object length #{request.body.length} cannot be cached by CDN; must be < 8KB") if request.body.length > 8000
      @logger.debug("[Experiment] Fetch variants for user: #{request.body}")
      response = http.request(request)
      end_time = Time.now
      elapsed = (end_time - start_time) * 1000.0
      @logger.debug("[Experiment] Fetch complete in #{elapsed.round(3)} ms")
      json = JSON.parse(response.body)
      variants = parse_json_variants(json)
      @logger.debug("[Experiment] Fetched variants: #{variants}")
      variants
    end

    # Parse JSON response hash
    #
    # @param [Hash] json
    # @return [Hash] Hash with String => Variant
    def parse_json_variants(json)
      variants = {}
      json.each do |key, value|
        variant_value = ''
        if value.key?('value')
          variant_value = value.fetch('value')
        elsif value.key?('key')
          # value was previously under the "key" field
          variant_value = value.fetch('key')
        end
        variants.store(key, Variant.new(variant_value, value.fetch('payload', nil)))
      end
      variants
    end

    # @param [User] user
    # @return [User, Hash] user with library context
    def add_context(user)
      user = {} if user.nil?
      user.library = "experiment-ruby-server/#{VERSION}"
      user
    end
  end
end
