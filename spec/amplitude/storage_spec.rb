module AmplitudeAnalytics
  describe Storage do
    before(:each) do
      @provider = InMemoryStorageProvider.new
      @storage = @provider.storage
      @workers = Workers.new
      @config = Config.new
      @storage.setup(@config, @workers)
      @workers.setup(@config, @storage)
    end

    it 'checks if storage is empty after pull' do
      expect(@storage.total_events).to eq(0)
      expect(@storage.pull(20)).to eq([])
    end

    it 'checks if storage is empty after pull_all' do
      expect(@storage.total_events).to eq(0)
      expect(@storage.pull_all).to eq([])
    end

    it 'checks wait_time with empty storage' do
      expect(@storage.total_events).to eq(0)
      expect(@storage.wait_time).to eq(FLUSH_INTERVAL_MILLIS)
    end

    it 'pushes new events to storage and pulls them' do
      expect(@storage.workers).to receive(:start).exactly(50).times
      event_list = []
      50.times do |i|
        event = BaseEvent.new("test_event_#{i}", user_id: 'test_user')
        @storage.push(event)
        event_list << event
      end

      expect(@storage.total_events).to eq(50)
      expect(@storage.ready_queue).to eq(event_list)
      expect(@storage.pull(30)).to eq(event_list.first(30))
      expect(@storage.total_events).to eq(20)
      expect(@storage.pull_all).to eq(event_list.last(20))
      expect(@storage.total_events).to eq(0)
    end

    it 'pushes events with delay and pulls them' do
      event_set = Set.new
      expect(@storage.workers).to receive(:start).exactly(50).times
      push_event(@storage, event_set, 50)

      expect(@storage.total_events).to eq(50)
      expect(@storage.ready_queue.length + @storage.buffer_data.length).to eq(50)
      storage_set = Set.new
      @storage.pull_all.each { |e| storage_set.add(e) }
      expect(storage_set).to eq(event_set)
    end

    it 'pushes events with multithreading and pulls them' do
      event_set = Set.new
      expect(@storage.workers).to receive(:start).exactly(100).times
      threads = []
      10.times do
        t = Thread.new { push_event(@storage, event_set, 10) }
        threads << t
      end

      threads.each(&:join)
      expect(@storage.total_events).to eq(100)
      expect(@storage.ready_queue.length + @storage.buffer_data.length).to eq(100)
      storage_set = Set.new
      @storage.pull_all.each { |e| storage_set.add(e) }
      expect(storage_set).to eq(event_set)
    end

    it 'exceeds max capacity and fails' do
      allow(@storage.workers).to receive(:start)
      @config.flush_interval_millis = 50_000
      push_event(@storage, Set.new, MAX_BUFFER_CAPACITY)
      expect(@storage.total_events).to eq(MAX_BUFFER_CAPACITY)
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event.retry += 1
      expect(@storage.workers).not_to receive(:start)
      is_success, message = @storage.push(event)
      expect(is_success).to be_falsey
      expect(message).to eq('Destination buffer full. Retry temporarily disabled')
    end

    it 'exceeds max retry and fails' do
      expect(@storage.workers).not_to receive(:start)
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event.retry = @storage.max_retry
      is_success, message = @storage.push(event)
      expect(is_success).to be_falsey
      expect(message).to eq("Event reached max retry times #{@storage.max_retry}.")
      expect(@storage.total_events).to eq(0)
    end

    it 'events in ready queue is zero' do
      allow(@storage.workers).to receive(:start)
      @storage.push(BaseEvent.new('test_event', user_id: 'test_user'), 0)
      expect(@storage.wait_time).to eq(0)
    end

    it 'event in buffer exceeds flush interval' do
      allow(@storage.workers).to receive(:start)
      @storage.push(BaseEvent.new('test_event', user_id: 'test_user'), 200)
      expect(@storage.wait_time > 0 && @storage.wait_time <= 200).to be_truthy
      @storage.pull_all
      @storage.push(BaseEvent.new('test_event', user_id: 'test_user'), FLUSH_INTERVAL_MILLIS + 500)
      expect(FLUSH_INTERVAL_MILLIS >= @storage.wait_time).to be_truthy
    end

    it 'verifies retry delay success' do
      allow(@storage.workers).to receive(:start)
      expect_delay = [0, 100, 100, 200, 200, 400, 400, 800, 800, 1600, 1600, 3200, 3200]
      expect_delay.each_with_index do |delay, retry_count|
        event = BaseEvent.new('test_event', user_id: 'test_user')
        event.retry = retry_count
        expect(@storage.retry_delay(event.retry)).to eq(delay)
      end
    end

    it 'from ready queue and buffer data' do
      allow(@storage.workers).to receive(:start)
      push_event(@storage, Set.new, 200)
      first_event_in_buffer_data = @storage.buffer_data[0][1]
      # Wait 100 ms - max delay of push_event()
      sleep(0.1)
      events = @storage.pull(@storage.ready_queue.length + 1)
      expect(first_event_in_buffer_data).to eq(events.last)
      expect(@storage.total_events).to eq(200 - events.length)
      expect(@storage.total_events).to eq(@storage.buffer_data.length)
    end

    private

    def push_event(storage, event_set, count)
      count.times do |i|
        event = BaseEvent.new("test_event_#{i}", user_id: 'test_user')
        storage.push(event, rand(101))
        event_set.add(event)
      end
    end
  end
end
