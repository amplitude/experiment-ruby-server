require 'net/http'
require 'json'
require 'uri'

module Experiment
  # Main client for fetching variant data.
  class Client
    # Creates a new Experiment Client instance.
    #
    # @param [String] api_key The environment API Key
    # @param [Config] config
    def initialize(api_key, config = nil)
      @api_key = api_key
      @config = config || Config.new
      raise ArgumentError, 'Experiment API key is empty' if @api_key.nil? || @api_key.empty?
    end

    # Fetch all variants for a user.
    #
    # This method will automatically retry if configured (default).
    # @param [User] user
    def fetch(user, &callback)
      thread = Thread.new do
        begin
          variants = fetch_internal(user)
          yield(user, variants) unless callback.nil?
          return variants
        rescue StandardError => error
          p "[Experiment] Failed to fetch variants: #{error.message}"
          yield(user, {}) unless callback.nil?
          return {}
        end
      end
      thread.begin
    end

    private

    # @param [User] user
    def fetch_internal(user)
      return do_fetch(user, @config.fetch_timeout_millis)
    rescue StandardError => error
      p error.message
      begin
        variants = retry_fetch(user)
        callback.call(user, variants) unless callback.nil?
        return variants
      rescue StandardError => err
        p err.message
      end
      throw error
    end

    # @param [User] user
    def retry_fetch(user)
      return {} if @config.fetch_retries.zero?
      delay_millis = @config.fetch_retry_backoff_min_millis
      err = nil
      @config.fetch_retries.times do
        sleep(delay_millis)
        begin
          return do_fetch(user, @config.fetch_retry_timeout_millis)
        rescue StandardError => error
          p "[Experiment] Retry failed: #{error.message}"
          err = error
        end
        delay_millis = [delay_millis * @config.fetch_retry_backoff_scalar, @config.fetch_retry_backoff_max_millis].min
      end
      throw err unless err.nil?
    end

    # @param [User] user
    # @param [Integer] timeout_millis
    def do_fetch(user, timeout_millis)
      user_context = add_context(user)
      endpoint = "#{@config.server_url}/sdk/vardata"
      headers = {
        'Authorization' => "Api-Key #{@api_key}",
        'Content-Type' => 'application/json;charset=utf-8'
      }
      uri = URI(endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = timeout_millis / 1000 if timeout_millis / 1000 > 0
      request = Net::HTTP::Post.new(uri, headers)
      request.body = user_context.to_json
      response = http.request(request)
      json = JSON.parse(response.body)
      parse_json_variants(json)
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
        variants.store(key, Variant.new(variant_value, value.fetch('payload')))
      end
      variants
    end

    # @param [User] user
    # @return [User, Hash] user with library context
    def add_context(user)
      user = {} if user.nil?
      user.library = "experiment-ruby-server/#{VERSION}" if user.library.nil?
      user
    end
  end
end
