module AmplitudeAnalytics
  describe Amplitude do
    let(:configuration) { Config.new(flush_queue_size: 10, flush_interval_millis: 500) }
    let(:client) { Amplitude.new(api_key: 'test api key', configuration: configuration) }

    it 'should track successfully' do
      allow(HttpClient).to receive(:post).and_return(Response.new(status: HttpStatus::SUCCESS))
      events = []
      callback_func = lambda do |event, code, _message = nil|
        expect(code).to eq(200)
        events << event.event_properties['id']
      end

      client.configuration.callback = callback_func

      [true, false].each do |use_batch|
        events.clear
        client.configuration.use_batch = use_batch
        25.times do |i|
          client.track(BaseEvent.new('test_event', user_id: 'test_user_id', event_properties: { 'id' => i }))
        end

        futures = client.flush
        futures.each do |flush_future|
          flush_future&.value
        end
        expect(events.length).to eq(25)
        expect(HttpClient).to have_received(:post).at_least(:once)
      end
    end
  end
end
