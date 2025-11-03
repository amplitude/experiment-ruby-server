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
      @logger = @config.logger
      endpoint = "#{@config.server_url}/sdk/v2/vardata?v=0"
      @uri = URI(endpoint)
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Fetch all variants for a user synchronously.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @return [Hash] Variants Hash
    def fetch(user)
      AmplitudeExperiment.filter_default_variants(fetch_internal(user, nil))
    rescue StandardError => e
      @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
      {}
    end

    # Fetch all variants for a user synchronously.
    #
    # This method will automatically retry if configured (default). This function differs from fetch as it will
    # return a default variant object if the flag was evaluated but the user was not assigned (i.e. off).
    # @param [User] user
    # @param [FetchOptions] fetch_options
    # @return [Hash] Variants Hash
    def fetch_v2(user, fetch_options = nil)
      fetch_internal(user, fetch_options)
    rescue StandardError => e
      @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
      {}
    end

    # Fetch all variants for a user asynchronously.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @yield [User, Hash] callback block takes user object and variants hash
    def fetch_async(user, &callback)
      Thread.new do
        variants = AmplitudeExperiment.filter_default_variants(fetch_internal(user, nil))
        yield(user, variants) unless callback.nil?
        variants
      rescue StandardError => e
        @logger.error("[Experiment] Failed to fetch variants: #{e.message}")
        yield(user, {}) unless callback.nil?
        {}
      end
    end

    # Fetch all variants for a user asynchronously. This function differs from fetch as it will
    # return a default variant object if the flag was evaluated but the user was not assigned (i.e. off).
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    # @yield [User, Hash] callback block takes user object and variants hash
    def fetch_async_v2(user, fetch_options = nil, &callback)
      Thread.new do
        variants = fetch_internal(user, fetch_options)
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
    # @param [FetchOptions] fetch_options
    def fetch_internal(user, fetch_options)
      @logger.debug("[Experiment] Fetching variants for user: #{user.as_json}")
      do_fetch(user, fetch_options, @config.connect_timeout_millis, @config.fetch_timeout_millis)
    rescue StandardError => e
      @logger.error("[Experiment] Fetch failed: #{e.message}")
      if should_retry_fetch?(e)
        begin
          retry_fetch(user, fetch_options)
        rescue StandardError => err
          @logger.error("[Experiment] Retry Fetch failed: #{err.message}")
        end
      end
      raise e
    end

    # @param [User] user
    # @param [FetchOptions] fetch_options
    def retry_fetch(user, fetch_options)
      return {} if @config.fetch_retries.zero?

      @logger.debug('[Experiment] Retrying fetch')
      delay_millis = @config.fetch_retry_backoff_min_millis
      err = nil
      @config.fetch_retries.times do
        sleep(delay_millis.to_f / 1000.0)
        begin
          return do_fetch(user, fetch_options, @config.connect_timeout_millis, @config.fetch_retry_timeout_millis)
        rescue StandardError => e
          @logger.error("[Experiment] Retry failed: #{e.message}")
          err = e
        end
        delay_millis = [delay_millis * @config.fetch_retry_backoff_scalar, @config.fetch_retry_backoff_max_millis].min
      end
      throw err unless err.nil?
    end

    # @param [User] user
    # @param [FetchOptions] fetch_options
    # @param [Integer] connect_timeout_millis
    # @param [Integer] fetch_timeout_millis
    def do_fetch(user, fetch_options, connect_timeout_millis, fetch_timeout_millis)
      start_time = Time.now
      user_context = add_context(user)
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8'
      }
      unless fetch_options.nil?
        unless fetch_options.tracks_assignment.nil?
          headers['X-Amp-Exp-Track'] = fetch_options.tracks_assignment ? 'track' : 'no-track'
        end
        unless fetch_options.tracks_exposure.nil?
          headers['X-Amp-Exp-Exposure-Track'] = fetch_options.tracks_exposure ? 'track' : 'no-track'
        end
      end
      connect_timeout = connect_timeout_millis.to_f / 1000 if (connect_timeout_millis.to_f / 1000) > 0
      read_timeout = fetch_timeout_millis.to_f / 1000 if (fetch_timeout_millis.to_f / 1000) > 0
      http = PersistentHttpClient.get(@uri, { open_timeout: connect_timeout, read_timeout: read_timeout }, @api_key)
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
      variants = AmplitudeExperiment.evaluation_variants_json_to_variants(json)
      @logger.debug("[Experiment] Fetched variants: #{variants}")
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
  end
end
