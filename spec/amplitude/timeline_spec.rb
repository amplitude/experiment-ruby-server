module AmplitudeAnalytics
  describe Timeline do
    before do
      @timeline = Timeline.new(Config.new)
    end

    it 'adds and removes plugins with types successfully' do
      before = EventPlugin.new(PluginType::BEFORE)
      enrich = EventPlugin.new(PluginType::ENRICHMENT)
      destination = AmplitudeDestinationPlugin.new

      @timeline.add(before)
      expect(@timeline.plugins[PluginType::BEFORE][0]).to eq(before)

      @timeline.add(enrich)
      expect(@timeline.plugins[PluginType::ENRICHMENT][0]).to eq(enrich)

      @timeline.add(destination)
      expect(@timeline.plugins[PluginType::DESTINATION][0]).to eq(destination)

      @timeline.remove(before)
      expect(@timeline.plugins[PluginType::BEFORE]).to be_empty

      @timeline.remove(enrich)
      expect(@timeline.plugins[PluginType::ENRICHMENT]).to be_empty

      @timeline.remove(destination)
      expect(@timeline.plugins[PluginType::DESTINATION]).to be_empty
    end

    it 'shuts down destination plugin successfully' do
      destination = instance_double(DestinationPlugin)
      allow(destination).to receive(:shutdown)
      allow(destination).to receive(:plugin_type).and_return(PluginType::DESTINATION)

      @timeline.add(destination)
      @timeline.shutdown

      expect(destination).to have_received(:shutdown).exactly(1).times
    end

    it 'flushes destination plugin successfully' do
      destination = instance_double(AmplitudeDestinationPlugin)
      allow(destination).to receive(:flush)
      allow(destination).to receive(:plugin_type).and_return(PluginType::DESTINATION)

      @timeline.add(destination)
      @timeline.flush

      expect(destination).to have_received(:flush).exactly(1).times
    end

    it 'processes event with plugin successfully' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event2 = BaseEvent.new('test_event', user_id: 'test_user', event_properties: { 'processed' => true })

      enrich = instance_double(EventPlugin)
      allow(enrich).to receive(:execute).and_return(event2)
      allow(enrich).to receive(:plugin_type).and_return(PluginType::ENRICHMENT)

      destination = instance_double(DestinationPlugin)
      allow(destination).to receive(:execute)
      allow(destination).to receive(:plugin_type).and_return(PluginType::DESTINATION)

      @timeline.add(enrich)
      @timeline.add(destination)

      result = @timeline.process(event)

      expect(result).to eq(event2)
      expect(enrich).to have_received(:execute).exactly(1).times
      expect(destination).to have_received(:execute).exactly(1).times
    end

    it 'processes event with plugin returns nil and stops' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event2 = BaseEvent.new('test_event', user_id: 'test_user', event_properties: { 'processed' => true })

      enrich1 = instance_double(EventPlugin)
      allow(enrich1).to receive(:execute).and_return(event2)
      allow(enrich1).to receive(:plugin_type).and_return(PluginType::ENRICHMENT)

      enrich2 = instance_double(EventPlugin)
      allow(enrich2).to receive(:execute).and_return(nil)
      allow(enrich2).to receive(:plugin_type).and_return(PluginType::ENRICHMENT)

      destination = instance_double(DestinationPlugin)
      allow(destination).to receive(:execute)
      allow(destination).to receive(:plugin_type).and_return(PluginType::DESTINATION)

      @timeline.add(enrich1)
      @timeline.add(enrich2)
      @timeline.add(destination)

      result = @timeline.process(event)

      expect(result).to be_nil
      expect(enrich1).to have_received(:execute).exactly(1).times
      expect(enrich2).to have_received(:execute).exactly(1).times
      expect(destination).to_not have_received(:execute)
    end

    it 'skips event processing with info log for opt-out config' do
      enrich = instance_double(EventPlugin)
      allow(enrich).to receive(:execute)
      allow(enrich).to receive(:plugin_type).and_return(PluginType::ENRICHMENT)

      allow(enrich).to receive(:execute)
      @timeline.add(enrich)
      @timeline.configuration.opt_out = true

      expect { @timeline.process(BaseEvent.new('test_event', user_id: 'test_user')) }.to output(/INFO -- amplitude: Skipped event for opt out config/).to_stdout

      expect(enrich).not_to have_received(:execute)
    end
  end
end
