module AmplitudeAnalytics
  describe Plugin do
    it 'initializes Amplitude client and sets up destination plugin' do
      allow(AmplitudeDestinationPlugin).to receive(:setup)
      expect_any_instance_of(AmplitudeDestinationPlugin).to receive(:setup)
      client = Amplitude.new('test_api_key')
      timeline = client.timeline
      expect(timeline.plugins[PluginType::DESTINATION]).to be_truthy
    end

    it 'initializes Amplitude client and creates context plugin' do
      client = Amplitude.new('test_api_key')
      timeline = client.timeline
      expect(timeline.plugins[PluginType::BEFORE]).to be_truthy
      context_plugin = timeline.plugins[PluginType::BEFORE][0]
      expect(context_plugin.plugin_type).to eq(PluginType::BEFORE)
      client.shutdown
    end

    it 'executes context plugin for event' do
      context_plugin = ContextPlugin.new
      client = Amplitude.new('test_api_key')
      context_plugin.setup(client)
      context_plugin.configuration.plan = Plan.new(source: 'test_source')
      event = BaseEvent.new('test_event', user_id: 'test_user')

      expect(event.time).to be_nil
      expect(event.insert_id).to be_nil
      expect(event.library).to be_nil
      expect(event.plan).to be_nil

      context_plugin.execute(event)

      expect(event.time).to be_an(Integer)
      expect(event.insert_id).to be_a(String)
      expect(event.library).to be_a(String)
      expect(event.plan).to be_a(Plan)
    end

    it 'processes event using event plugin' do
      plugin = EventPlugin.new(PluginType::BEFORE)
      event = BaseEvent.new('test_event', user_id: 'test_user')

      expect(plugin.execute(event)).to eq(event)
      expect(plugin.track(event)).to eq(event)
    end

    it 'adds and removes context plugin using destination plugin' do
      destination_plugin = DestinationPlugin.new
      destination_plugin.timeline.configuration = Config.new
      context_plugin = ContextPlugin.new
      context_plugin.configuration = destination_plugin.timeline.configuration
      event = BaseEvent.new('test_event', user_id: 'test_user')

      destination_plugin.add(context_plugin)
      destination_plugin.execute(event)

      expect(event.time).to be_an(Integer)
      expect(event.insert_id).to be_a(String)
      expect(event.library).to be_a(String)

      destination_plugin.remove(context_plugin)
      event = BaseEvent.new('test_event', user_id: 'test_user')
      destination_plugin.execute(event)

      expect(event.time).to be_nil
      expect(event.insert_id).to be_nil
      expect(event.library).to be_nil
    end
  end
end
