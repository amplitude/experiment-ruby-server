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
      endpoint = "#{@config.server_url}/sdk/v2/vardata?v=0"
      @uri = URI(endpoint)
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Fetch all variants for a user synchronous.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @return [Hash] Variants Hash
    def fetch(user)
      filter_default_variants(fetch_internal(user))
    rescue StandardError => e
      @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
      {}
    end

    # Fetch all variants for a user synchronous.
    #
    # This method will automatically retry if configured (default). This function differs from fetch as it will
    # return a default variant object if the flag was evaluated but the user was not assigned (i.e. off).
    # @param [User] user
    # @return [Hash] Variants Hash
    def fetch_v2(user)
      fetch_internal(user)
    rescue StandardError => e
      @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
      {}
    end

    # Fetch all variants for a user asynchronous.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @yield [User, Hash] callback block takes user object and variants hash
    def fetch_async(user, &callback)
      Thread.new do
        variants = fetch_internal(user)
        yield(user, variants) unless callback.nil?
        variants
      rescue StandardError => e
        @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
        yield(user, {}) unless callback.nil?
        {}
      end
    end

    # Fetch all variants for a user asynchronous. This function differs from fetch as it will
    # return a default variant object if the flag was evaluated but the user was not assigned (i.e. off).
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @yield [User, Hash] callback block takes user object and variants hash
    def fetch_async_v2(user, &callback)
      Thread.new do
        variants = fetch_internal(user)
        yield(user, filter_default_variants(variants)) unless callback.nil?
        variants
      rescue StandardError => e
        @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
        yield(user, {}) unless callback.nil?
        {}
      end
    end

    private

    # @param [User] user
    def fetch_internal(user)
      @logger.debug("[Experiment] Fetching variants for user: #{user.as_json}")
      do_fetch(user, @config.fetch_timeout_millis)
    rescue StandardError => e
      @logger.error("[Experiment] Fetch failed: #{e.message}")
      if should_retry_fetch?(e)
        begin
          retry_fetch(user)
        rescue StandardError => err
          @logger.error("[Experiment] Retry Fetch failed: #{err.message}")
        end
      end
      raise e
    end

    # @param [User] user
    def retry_fetch(user)
      return {} if @config.fetch_retries.zero?

      @logger.debug('[Experiment] Retrying fetch')
      delay_millis = @config.fetch_retry_backoff_min_millis
      err = nil
      @config.fetch_retries.times do
        sleep(delay_millis.to_f / 1000.0)
        begin
          return do_fetch(user, @config.fetch_retry_timeout_millis)
        rescue StandardError => e
          @logger.error("[Experiment] Retry failed: #{e.message}")
          err = e
        end
        delay_millis = [delay_millis * @config.fetch_retry_backoff_scalar, @config.fetch_retry_backoff_max_millis].min
      end
      throw err unless err.nil?
    end

    # @param [User] user
    # @param [Integer] timeout_millis
    def do_fetch(user, timeout_millis)
      start_time = Time.now
      user_context = add_context(user)
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8'
      }
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
      raise FetchError.new(response.code.to_i, "Fetch error response: status=#{response.code} #{response.message}") if response.code != '200'

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
        variants.store(key, Variant.new(variant_value, value.fetch('payload', nil), value.fetch('metadata', nil)))
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

    def should_retry_fetch?(err)
      return err.status_code < 400 || err.status_code >= 500 || err.status_code == 429 if err.is_a?(FetchError)

      true
    end

    def filter_default_variants(variants)
      variants.each do |key, value|
        default = value&.metadata&.default
        deployed = value&.metadata&.deployed
        default ||= false
        deployed ||= true
        variants.delete(key) if default || !deployed
      end
      variants
    end

    private :filter_default_variants
  end
end
