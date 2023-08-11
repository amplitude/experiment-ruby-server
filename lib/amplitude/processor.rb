module AmplitudeAnalytics
  # ResponseProcessor
  class ResponseProcessor
    attr_accessor :configuration, :storage

    def initialize
      @configuration = nil
      @storage = nil
    end

    def setup(configuration, storage)
      @configuration = configuration
      @storage = storage
    end

    def process_response(res, events)
      case res.status
      when HttpStatus::SUCCESS
        callback(events, res.code, 'Event sent successfully.')
        log(events, res.code, 'Event sent successfully.')
      when HttpStatus::TIMEOUT, HttpStatus::FAILED
        push_to_storage(events, 0, res)
      when HttpStatus::PAYLOAD_TOO_LARGE
        if events.length == 1
          callback(events, res.code, res.error)
          log(events, res.code, res.error)
        else
          @configuration.increase_flush_divider
          push_to_storage(events, 0, res)
        end
      when HttpStatus::INVALID_REQUEST
        raise InvalidAPIKeyError, res.error if res.error.start_with?('Invalid API key:')

        if res.missing_field
          callback(events, res.code, "Request missing required field #{res.missing_field}")
          log(events, res.code, "Request missing required field #{res.missing_field}")
        else
          invalid_index_set = res.invalid_or_silenced_index
          events_for_retry = []
          events_for_callback = []
          events.each_with_index do |event, index|
            if invalid_index_set.include?(index)
              events_for_callback << event
            else
              events_for_retry << event
            end
          end
          callback(events_for_callback, res.code, res.error)
          log(events_for_callback, res.code, res.error)
          push_to_storage(events_for_retry, 0, res)
        end
      when HttpStatus::TOO_MANY_REQUESTS
        events_for_callback = []
        events_for_retry_delay = []
        events_for_retry = []
        events.each_with_index do |event, index|
          if res.throttled_events&.include?(index)
            if res.exceed_daily_quota(event)
              events_for_callback << event
            else
              events_for_retry_delay << event
            end
          else
            events_for_retry << event
          end
        end
        callback(events_for_callback, res.code, 'Exceeded daily quota')
        push_to_storage(events_for_retry_delay, 30_000, res)
        push_to_storage(events_for_retry, 0, res)
      else
        callback(events, res.code, res.error || 'Unknown error')
        log(events, res.code, res.error || 'Unknown error')
      end
    end

    def push_to_storage(events, delay, res)
      events.each do |event|
        event.retry += 1
        success, message = @storage.push(event, delay)
        unless success
          callback([event], res.code, message)
          log([event], res.code, message)
        end
      end
    end

    def callback(events, code, message)
      events.each do |event|
        @configuration.callback.call(event, code, message) if @configuration.callback.respond_to?(:call)
        event.callback(code, message)
      rescue StandardError => e
        @configuration.logger.exception("Error callback for event #{event}: #{e.message}")
      end
    end

    def log(events, code, message)
      events.each do |event|
        @configuration.logger.info("#{message}, response code: #{code}, event: #{event}")
      end
    end
  end
end
