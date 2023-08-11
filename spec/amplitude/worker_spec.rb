module AmplitudeAnalytics
  describe Workers do
    before(:each) do
      @workers = Workers.new
      @workers.setup(Config.new, InMemoryStorage.new)
      @workers.storage.setup(@workers.configuration, @workers)
      @events_dict = Hash.new { |hash, key| hash[key] = Set.new }

      callback_func = lambda do |event, code, message = nil|
        @events_dict[code].add(event)
      end

      @workers.configuration.callback = callback_func
    end

    after(:each) do
      @workers.storage.lock { @workers.storage.lock.signal }
    end

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
      expect(@workers.storage).to have_received(:pull_all).once
    end

    it 'gets payload successfully' do
      events = [BaseEvent.new('test_event1', user_id: 'test_user'), BaseEvent.new('test_event2', user_id: 'test_user')]
      @workers.configuration.api_key = 'TEST_API_KEY'
      expect_payload = '{"api_key": "TEST_API_KEY", "events": [{"event_type": "test_event1", "user_id": "test_user"}, {"event_type": "test_event2", "user_id": "test_user"}]}'
      expect(@workers.get_payload(events)).to eq(expect_payload)

      @workers.configuration.min_id_length = 3
      expect_payload = '{"api_key": "TEST_API_KEY", "events": [{"event_type": "test_event1", "user_id": "test_user"}, {"event_type": "test_event2", "user_id": "test_user"}], "options": {"min_id_length": 3}}'
      expect(@workers.get_payload(events)).to eq(expect_payload)
    end

    it 'consumes storage events successfully' do
      success_response = Response.new(status: HttpStatus::SUCCESS)
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

  end
end
