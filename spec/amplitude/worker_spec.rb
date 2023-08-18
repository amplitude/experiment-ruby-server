module AmplitudeAnalytics
  describe Workers do
    let(:success_response) { Response.new(status: HttpStatus::SUCCESS) }
    let(:failed_response) { Response.new(status: HttpStatus::FAILED) }
    let(:timeout_response) { Response.new(status: HttpStatus::TIMEOUT) }
    let(:unknown_error_response) { Response.new(status: HttpStatus::UNKNOWN) }
    let(:payload_too_large_response) { Response.new(status: HttpStatus::PAYLOAD_TOO_LARGE) }

    before(:each) do
      @workers = Workers.new
      @workers.setup(Config.new, InMemoryStorage.new)
      @workers.storage.setup(@workers.configuration, @workers)
      @events_dict = Hash.new { |hash, key| hash[key] = Set.new }
      @events_dict_mutex = Mutex.new

      callback_func = lambda do |event, code, message = nil|
        @events_dict_mutex.synchronize do
          @events_dict[code].add(event)
        end
      end

      @workers.configuration.callback = callback_func
    end

    after(:each) do
      @workers.storage.monitor.synchronize do
        @workers.storage.lock.signal
      end
    end

    it 'initializes and sets up correctly' do
      expect(@workers.is_active).to be_truthy
      expect(@workers.is_started).to be_falsy
      expect(@workers.storage).not_to be_nil
      expect(@workers.configuration).not_to be_nil
      expect(@workers.threads_pool).not_to be_nil
      expect(@workers.consumer_lock).not_to be_nil
      expect(@workers.response_processor).not_to be_nil
    end

    it 'stops successfully' do
      allow(@workers.storage).to receive(:pull_all)
      @workers.stop
      expect(@workers.is_active).to be_falsy
      expect(@workers.is_started).to be_truthy
      sleep(1)
      expect(@workers.storage).to have_received(:pull_all).once
    end

    it 'gets payload successfully' do
      events = [BaseEvent.new('test_event1', user_id: 'test_user'), BaseEvent.new('test_event2', user_id: 'test_user')]
      @workers.configuration.api_key = 'TEST_API_KEY'
      expect_payload = '{"api_key":"TEST_API_KEY","events":[{"event_type":"test_event1","user_id":"test_user"},{"event_type":"test_event2","user_id":"test_user"}]}'
      expect(@workers.get_payload(events)).to eq(expect_payload)

      @workers.configuration.min_id_length = 3
      expect_payload = '{"api_key":"TEST_API_KEY","events":[{"event_type":"test_event1","user_id":"test_user"},{"event_type":"test_event2","user_id":"test_user"}],"options":{"min_id_length":3}}'
      expect(@workers.get_payload(events)).to eq(expect_payload)
    end

    it 'consumes storage events successfully' do
      allow(HttpClient).to receive(:post).and_return(success_response)

      @workers.configuration.flush_interval_millis = 10
      push_event(get_events_list(50))
      expect(@workers.is_started).to be true
      sleep(@workers.configuration.flush_interval_millis / 1000 + 1)
      expect(@events_dict[200].size).to eq(50)
      expect(@workers.is_started).to be false
      push_event(get_events_list(50))
      expect(@workers.is_started).to be true
      expect(HttpClient).to have_received(:post).at_least(:once)
    end

    it 'flushes events in storage successfully' do
      allow(HttpClient).to receive(:post).and_return(success_response)
      push_event(get_events_list(50))
      @workers.flush&.value
      expect(@events_dict[200].length).to eq(50)
      expect(HttpClient).to have_received(:post).at_least(:once)
    end

    it 'sends events with success response and triggers callback' do
      allow(HttpClient).to receive(:post).and_return(success_response)
      events = get_events_list(100)
      @workers.send(events)
      expect(@events_dict[200]).to eq(Set.new(events))
    end

    it 'sends events with invalid request response and triggers callback' do
      events = get_events_list(100)
      invalid_response = Response.new(status: HttpStatus::INVALID_REQUEST)
      invalid_response.body = {
        "code" => 400,
        "error" => "Test error",
        "events_with_invalid_fields" => {
          "time" => [0, 1, 2, 3, 4, 5]
        },
        "events_with_missing_fields" => {
          "event_type": [5, 6, 7, 8, 9]
        },
        "events_with_invalid_id_lengths" => {
          "user_id" => [10, 11, 12],
          "device_id" => [13, 14, 15]
        },
        "silenced_events" => [16, 17, 18, 19]
      }
      allow(HttpClient).to receive(:post).and_return(invalid_response, success_response)

      @workers.send(events)
      @workers.flush&.value

      expect(@events_dict[200]).to eq(Set.new(events[20..]))
      (20..99).each { |i| expect(events[i].retry).to eq(1) }
      expect(@events_dict[400]).to eq(Set.new(events[0..19]))
      expect(HttpClient).to have_received(:post).twice
    end

    it 'sends events with invalid response missing field and no retry' do
      events = get_events_list(100)
      invalid_response = Response.new(status: HttpStatus::INVALID_REQUEST)
      invalid_response.body = {
        "code" => 400,
        "error" => "Test error",
        "missing_field" => "api_key"
      }
      allow(HttpClient).to receive(:post).and_return(invalid_response)

      @workers.send(events)

      expect(@events_dict[400].length).to eq(100)
      events.each { |e| expect(e.retry).to eq(0) }
    end

    it 'sends events with invalid response and raises API key error' do
      events = get_events_list(100)
      invalid_response = Response.new(status: HttpStatus::INVALID_REQUEST)
      invalid_response.body = {
        "code" => 400,
        "error" => "Invalid API key: TEST_API_KEY"
      }
      allow(HttpClient).to receive(:post).and_return(invalid_response)
      logs_output = []
      allow(@workers.configuration.logger).to receive(:error) { |block| logs_output << block.to_s }
      @workers.send(events)
      expect(logs_output).to include('Invalid API Key')

      expect(@events_dict[400].length).to eq(0)
    end

    it 'handles payload too large response and decreases flush queue size' do
      events = get_events_list(30)
      allow(HttpClient).to receive(:post).and_return(payload_too_large_response, payload_too_large_response, success_response)

      @workers.configuration.flush_queue_size = 30
      @workers.send(events)
      expect(@workers.configuration.flush_queue_size).to eq(15)
      @workers.flush&.value
      expect(@workers.configuration.flush_queue_size).to eq(10)
      @workers.flush&.value
      expect(@events_dict[200].length).to eq(30)
    end

    it "retries events on timeout and failed response" do
      events = get_events_list(100)
      allow(HttpClient).to receive(:post).and_return(timeout_response, failed_response, success_response)

      @workers.send(events)
      @workers.flush&.value
      @workers.flush&.value

      expect(@events_dict[200].length).to eq(100)
      expect(HttpClient).to have_received(:post).exactly(3).times
    end

    it "triggers callback on unknown error" do
      allow(HttpClient).to receive(:post).and_return(unknown_error_response)

      @workers.send(get_events_list(100))

      expect(@events_dict[-1].length).to eq(100)
      expect(HttpClient).to have_received(:post).once

      @workers.flush
      expect(HttpClient).to have_received(:post).once
    end

    it "handles too many requests response, triggers callback, and retries" do
      too_many_requests_response = Response.new(status: HttpStatus::TOO_MANY_REQUESTS, body: {
        "code" => 429,
        "error" => "Too many requests for some devices and users",
        "eps_threshold" => 10,
        "throttled_devices" => { "test_throttled_device" => 11 },
        "throttled_users" => { "test_throttled_user" => 12 },
        "exceeded_daily_quota_users" => { "test_throttled_user2" => 500200 },
        "exceeded_daily_quota_devices" => { "test_throttled_device2" => 600200 },
        "throttled_events" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      })
      events = get_events_list(100)
      events[0].user_id = "test_throttled_user2"
      events[1].device_id = "test_throttled_device2"
      allow(HttpClient).to receive(:post).and_return(too_many_requests_response, success_response, success_response)

      @workers.send(events)
      expect(@events_dict[429]).to eq(Set.new(events.first(2)))
      i = -1
      while i > -15
        expect(events[16 + i]).to eq(@workers.instance_variable_get(:@storage).buffer_data[i][1])
        i -= 1
      end
      @workers.flush&.value
      expect(@events_dict[200]).to eq(Set.new(events[2..]))
    end

    it 'processes events with random response in multithreaded mode' do

      too_many_requests_response = Response.new(status: HttpStatus::TOO_MANY_REQUESTS, body: {
        "code" => 429,
        "error" => "Too many requests for some devices and users",
        "eps_threshold" => 10,
        "exceeded_daily_quota_users" => { "test_user" => 500200 },
        "throttled_events" => [0]
      })
      invalid_response = Response.new(status: HttpStatus::INVALID_REQUEST, body: {
        "code" => 400,
        "error" => "Test error",
        "events_with_invalid_fields" => {
          "time" => [0]
        }
      })

      r = Random.new(200)

      allow(HttpClient).to receive(:post) do |_url, _payload|
        i = r.rand(0..100)
        case i
        when 0..2 then timeout_response
        when 3..5 then unknown_error_response
        when 6..8 then too_many_requests_response
        when 9..11 then failed_response
        when 12..14 then payload_too_large_response
        when 15..17 then invalid_response
        else success_response
        end
      end

      [@workers.method(:send), method(:push_event)].each do |target_func|
        threads = []
        @events_dict.clear
        50.times do
          t = Thread.new do
            target_func.call(get_events_list(100))
          end
          threads << t
        end
        threads.each(&:join)
        sleep(5)
        while @workers.storage.total_events > 0
          sleep(0.1)
        end
        expect(@workers.storage.total_events).to eq(0)
        total_events = @events_dict.values.sum(&:length)
        expect(total_events).to eq(5000)
      end
    end

    private

    def push_event(events)
      events.each do |event|
        @workers.storage.push(event)
      end
    end

    def get_events_list(num)
      events = []
      num.times do |i|
        events.append(BaseEvent.new("test_event_#{i}", user_id: 'test_user'))
      end
      events
    end
  end
end
