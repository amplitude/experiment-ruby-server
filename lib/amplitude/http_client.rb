require 'json'
require 'net/http'
require 'uri'

module AmplitudeAnalytics
  JSON_HEADER = {
    'Content-Type': 'application/json; charset=UTF-8',
    Accept: '*/*'
  }.freeze

  # HttpStatus
  class HttpStatus
    attr_reader :value

    def initialize(value)
      @value = value
    end

    SUCCESS = new(200)
    INVALID_REQUEST = new(400)
    TIMEOUT = new(408)
    PAYLOAD_TOO_LARGE = new(413)
    TOO_MANY_REQUESTS = new(429)
    FAILED = new(500)
    UNKNOWN = new(-1)
  end

  # Response
  class Response
    attr_accessor :status, :code, :body

    def initialize(status: HttpStatus::UNKNOWN, body: nil)
      @status = status
      @code = status.value
      @body = body || {}
    end

    def parse(res)
      res_body = JSON.parse(res.body)
      @code = res_body['code']
      @status = get_status(@code)
      @body = res_body
      self
    end

    def get_status(code)
      case code
      when 200
        HttpStatus::SUCCESS
      when 400
        HttpStatus::INVALID_REQUEST
      when 408
        HttpStatus::TIMEOUT
      when 413
        HttpStatus::PAYLOAD_TOO_LARGE
      when 429
        HttpStatus::TOO_MANY_REQUESTS
      when 500
        HttpStatus::FAILED
      else
        HttpStatus::UNKNOWN
      end
    end

    def error
      @body['error'] if @body.key?('error')
    end

    def missing_field
      @body['missing_field'] if @body.key?('missing_field')
    end

    def events_with_invalid_fields
      @body['events_with_invalid_fields'] if @body.key?('events_with_invalid_fields')
    end

    def events_with_missing_fields
      @body['events_with_missing_fields'] if @body.key?('events_with_missing_fields')
    end

    def events_with_invalid_id_lengths
      @body['events_with_invalid_id_lengths'] if @body.key?('events_with_invalid_id_lengths')
    end

    def silenced_events
      @body['silenced_events'] if @body.key?('silenced_events')
    end

    def throttled_events
      @body['throttled_events'] if @body.key?('throttled_events')
    end

    def exceed_daily_quota(event)
      return true if @body.key?('exceeded_daily_quota_users') && @body['exceeded_daily_quota_users'].include?(event.user_id)
      if @body.key?('exceeded_daily_quota_devices') && @body['exceeded_daily_quota_devices'].include?(event.device_id)
        return true
      end

      false
    end

    def invalid_or_silenced_index
      result = Set.new
      result.merge(@body['events_with_missing_fields'].values.flatten) if @body.key?('events_with_missing_fields')
      result.merge(@body['events_with_invalid_fields'].values.flatten) if @body.key?('events_with_invalid_fields')
      result.merge(@body['events_with_invalid_id_lengths'].values.flatten) if @body.key?('events_with_invalid_id_lengths')
      result.merge(@body['silenced_events']) if @body.key?('silenced_events')
      result.to_a
    end

    def self.get_status(code)
      case code
      when 200..299
        HttpStatus::SUCCESS
      when 429
        HttpStatus::TOO_MANY_REQUESTS
      when 413
        HttpStatus::PAYLOAD_TOO_LARGE
      when 408
        HttpStatus::TIMEOUT
      when 400..499
        HttpStatus::INVALID_REQUEST
      when 500..Float::INFINITY
        HttpStatus::FAILED
      else
        HttpStatus::UNKNOWN
      end
    end
  end

  # HttpClient
  class HttpClient
    def self.post(url, payload, header = nil)
      result = Response.new
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host || '', uri.port)
        http.use_ssl = uri.scheme == 'https'

        headers = header || JSON_HEADER
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = payload
        res = http.request(request)
        result.parse(res)
      rescue Net::ReadTimeout
        result.code = 408
        result.status = HttpStatus::TIMEOUT
      rescue Net::HTTPError => e
        begin
          result.parse(e)
        rescue StandardError
          result = Response.new
          result.code = e.response.code.to_i
          result.status = Response.get_status(e.response.code.to_i)
          result.body = { 'error' => e.response.message }
        end
      rescue Net::OpenTimeout => e
        result.body = { 'error' => e.message }
      end
      result
    end
  end
end
