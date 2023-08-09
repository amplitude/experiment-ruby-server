require 'json'
require 'concurrent'

module AmplitudeAnalytics
  # Workers
  class Workers
    def initialize
      @threads_pool = Concurrent::ThreadPoolExecutor.new(max_threads: 16)
      @is_active = true
      @consumer_lock = Mutex.new
      @is_started = false
      @configuration = nil
      @storage = nil
      @response_processor = ResponseProcessor.new
    end

    def setup(configuration, storage)
      @configuration = configuration
      @storage = storage
      @response_processor = ResponseProcessor.new
      @response_processor.setup(configuration, storage)
    end

    def start
      @consumer_lock.synchronize do
        unless @is_started
          @is_started = true
          Thread.new { buffer_consumer }
        end
      end
    end

    def stop
      flush
      @is_active = false
      @is_started = true
      @threads_pool.shutdown
    end

    def flush
      Concurrent::Future.execute do
        events = @storage.pull_all
        if events && !events.empty?
          send(events)
        end
      end
    end

    def send(events)
      url = @configuration.server_url
      payload = get_payload(events)
      res = HttpClient.post(url, payload)
      begin
        @response_processor.process_response(res, events)
      rescue InvalidAPIKeyError
        @configuration.logger.error('Invalid API Key')
      end
    end

    def get_payload(events)
      payload_body = {
        'api_key' => @configuration.api_key,
        'events' => [],
        'options' => {}
      }

      events.each do |event|
        event_body = event.event_body
        payload_body['events'] << event_body if event_body
      end
      payload_body['options'] = @configuration.options if @configuration.options
      JSON.dump(payload_body).encode('utf-8')
    end

    def buffer_consumer
      if @is_active
        @storage.lock.synchronize do
          @storage.lock.wait(@configuration.flush_interval_millis / 1000)

          loop do
            break unless @storage.total_events.positive?

            events = @storage.pull(@configuration.flush_queue_size)
            if events
              @threads_pool.submit { send(events) }
            else
              wait_time = @storage.wait_time / 1000
              @storage.lock.wait(wait_time) if wait_time > 0
            end
          end
        end
      end
    rescue StandardError => e
      @configuration.logger.error("Consumer thread error: #{e}")
    ensure
      @consumer_lock.synchronize do
        @is_started = false
      end
    end
  end
end
