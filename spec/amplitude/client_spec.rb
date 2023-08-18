module AmplitudeAnalytics
  describe Amplitude do
    before(:each) do
      @client = Amplitude.new('test api key', configuration: Config.new(flush_queue_size: 10, flush_interval_millis: 500))
    end

    after(:each) do
      @client.shutdown
    end

    it 'should track successfully' do
      allow(HttpClient).to receive(:post).and_return(Response.new(status: HttpStatus::SUCCESS))
      events = []
      callback_func = lambda do |event, code, _message = nil|
        expect(code).to eq(200)
        events << event.event_properties['id']
      end

      @client.configuration.callback = callback_func

      [true, false].each do |use_batch|
        events.clear
        @client.configuration.use_batch = use_batch
        25.times do |i|
          @client.track(BaseEvent.new('test_event', user_id: 'test_user_id', event_properties: { 'id' => i }))
        end

        futures = @client.flush
        futures.each do |flush_future|
          flush_future&.value
        end
        expect(events.length).to eq(25)
        expect(HttpClient).to have_received(:post).at_least(:once)
      end
    end

    it 'tracks with invalid API key and logs an error' do
      res = Response.new(status: HttpStatus::INVALID_REQUEST)
      res.body['error'] = "Invalid API key: #{@client.configuration.api_key}"
      allow(HttpClient).to receive(:post).and_return(res)

      [true, false].each do |use_batch|
        @client.configuration.use_batch = use_batch

        logs_output = []
        allow(@client.configuration.logger).to receive(:error) { |block| logs_output << block.to_s }

        @client.track(BaseEvent.new('test_event', user_id: 'test_user_id'))
        futures = @client.flush
        futures.each { |flush_future| flush_future&.value }

        expect(logs_output).to include('Invalid API Key')
        expect(HttpClient).to have_received(:post).at_least(:once)
      end
    end

    it 'tracks with invalid response, then success response' do
      invalid_response = Response.new(status: HttpStatus::INVALID_REQUEST)
      invalid_response.body = {
        'code' => 400,
        'error' => 'Invalid events',
        'events_with_invalid_fields' => {
          'time' => [1, 5, 8]
        },
        'events_with_missing_fields' => {
          'event_type' => [2, 5, 6]
        }
      }

      success_response = Response.new(status: HttpStatus::SUCCESS)
      events = []

      callback_func = lambda do |event, code, message = nil|
        if [1, 2, 5, 6, 8].include?(event.event_properties['id'])
          expect(code).to eq(400)
        else
          expect(code).to eq(200)
        end
        events << [event.event_properties['id'], event.retry]
      end

      @client.configuration.callback = callback_func

      [true, false].each do |use_batch|
        @client.configuration.use_batch = use_batch
        allow(HttpClient).to receive(:post).and_return(invalid_response, success_response)
        expect(HttpClient).to receive(:post).exactly(:twice)

        events.clear
        (0..9).each do |i|
          @client.track(BaseEvent.new('test_event', user_id: 'test_user_id', event_properties: { 'id' => i }))
        end

        @client.flush
        sleep(0.1) while events.length < 10
        expect(events).to eq([[1, 0], [2, 0], [5, 0], [6, 0], [8, 0], [0, 1], [3, 1], [4, 1], [7, 1], [9, 1]])
      end
    end

    it 'flushes successfully' do
      callback_func = lambda do |event, code, _message = nil|
        expect(code).to eq(200)
        expect(event['event_type']).to eq('flush_test')
        expect(event['user_id']).to eq('test_user_id')
        expect(event['device_id']).to eq('test_device_id')
      end

      @client.configuration.callback = callback_func

      [true, false].each do |use_batch|
        expect(HttpClient).to receive(:post).exactly(:once)
        @client.configuration.use_batch = use_batch
        @client.track(BaseEvent.new('flush_test', user_id: 'test_user_id', device_id: 'test_device_id'))
        futures = @client.flush
        futures.each { |flush_future| flush_future&.value }
      end
    end

    it 'adds and removes plugins successfully' do
      timeline = @client.timeline
      before_plugin = EventPlugin.new(PluginType::BEFORE)
      enrich_plugin = EventPlugin.new(PluginType::ENRICHMENT)
      destination_plugin = DestinationPlugin.new

      expect(destination_plugin.plugin_type).to eq(PluginType::DESTINATION)
      expect(timeline.plugins[PluginType::BEFORE].length).to eq(1)

      @client.add(before_plugin)
      expect(timeline.plugins[PluginType::BEFORE].length).to eq(2)
      expect(timeline.plugins[PluginType::BEFORE][-1]).to eq(before_plugin)
      expect(timeline.plugins[PluginType::ENRICHMENT].length).to eq(0)

      @client.add(enrich_plugin)
      expect(timeline.plugins[PluginType::ENRICHMENT].length).to eq(1)
      expect(timeline.plugins[PluginType::ENRICHMENT][-1]).to eq(enrich_plugin)
      expect(timeline.plugins[PluginType::DESTINATION].length).to eq(1)

      @client.add(destination_plugin)
      expect(timeline.plugins[PluginType::DESTINATION].length).to eq(2)
      expect(timeline.plugins[PluginType::DESTINATION][-1]).to eq(destination_plugin)

      @client.remove(before_plugin)
      expect(timeline.plugins[PluginType::BEFORE].length).to eq(1)
      expect(timeline.plugins[PluginType::BEFORE][-1]).not_to eq(before_plugin)

      @client.remove(enrich_plugin)
      expect(timeline.plugins[PluginType::ENRICHMENT].length).to eq(0)

      @client.remove(destination_plugin)
      expect(timeline.plugins[PluginType::DESTINATION].length).to eq(1)
      expect(timeline.plugins[PluginType::DESTINATION][-1]).not_to eq(destination_plugin)
    end
  end
end

