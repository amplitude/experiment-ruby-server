module AmplitudeAnalytics
  describe EventOptions do
    it 'event_options_create_instance_with_attributes_success' do
      event_option = EventOptions.new(user_id: 'test_user_id')
      expect(event_option).to include('user_id')
      expect(event_option).not_to include('device_id')
      expect(event_option.user_id).to eq('test_user_id')
      expect(event_option['user_id']).to eq('test_user_id')
    end

    it 'base_event_create_instance_has_proper_retry_value' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expect(event.retry).to eq(0)
      event.retry += 1
      expect(event.retry).to eq(1)
    end

    it 'base_event_to_json_string_success' do
      event = BaseEvent.new('test_event', user_id: 'test_user', event_id: 10)
      expect(event.to_s).to eq('{"event_id":10,"event_type":"test_event","user_id":"test_user"}')
    end

    it 'base_event_set_plan_attribute_success' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event['plan'] = Plan.new(branch: 'test_branch', version_id: 'v1.1')
      expect(event.event_body).to eq({
                                       'user_id' => 'test_user',
                                       'event_type' => 'test_event',
                                       'plan' => { 'branch' => 'test_branch', 'versionId' => 'v1.1' }
                                     })
    end

    it 'base_event_set_ingestion_metadata_attribute_success' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event['ingestion_metadata'] = IngestionMetadata.new(source_name: 'test_source', source_version: 'test_version')
      expect(event.event_body).to eq({
                                       'user_id' => 'test_user',
                                       'event_type' => 'test_event',
                                       'ingestion_metadata' => { 'source_name' => 'test_source', 'source_version' => 'test_version' }
                                     })
    end

    it 'loads event options and updates attributes value' do
      event = BaseEvent.new('test_event', event_properties: { 'properties1' => 'test' }, time: 0)
      event_options = EventOptions.new(
        user_id: 'test_user',
        device_id: 'test_device',
        time: 10,
        ingestion_metadata: IngestionMetadata.new(source_name: 'test_source', source_version: 'test_version')
      )
      event.load_event_options(event_options)

      expected_event_body = {
        'user_id' => 'test_user',
        'device_id' => 'test_device',
        'time' => 10,
        'ingestion_metadata' => { 'source_name' => 'test_source', 'source_version' => 'test_version' },
        'event_type' => 'test_event',
        'event_properties' => { 'properties1' => 'test' }
      }

      expect(event.event_body).to eq(expected_event_body)
    end

    it 'invokes callback function successfully when callback is provided' do
      callback_func = double('callback_func')
      test_event = BaseEvent.new('test_event', callback: callback_func)
      expect(callback_func).to receive(:call).with(test_event, 200, 'Test Message')
      test_event.callback(200, 'Test Message')
    end

    it 'does not invoke callback function when callback is nil' do
      callback_func = double('callback_func')
      test_event = BaseEvent.new('test_event', callback: nil)
      expect(callback_func).not_to receive(:call)
      test_event.callback(200, 'Test Message')
    end

    # TODO: implement ENUM testing
    # it 'returns event body successfully with enum properties' do
    #   TestEnum = Struct.new(:value) do
    #     ENUM1 = TestEnum.new('test')
    #     ENUM2 = TestEnum.new('test2')
    #   end
    #
    #   event = BaseEvent.new(
    #     event_type: 'test_event',
    #     user_id: 'test_user',
    #     user_properties: { 'email' => 'test@test' },
    #     event_properties: { 'enum_properties' => TestEnum::ENUM1 }
    #   )
    #
    #   expected_dict = {
    #     'event_type' => 'test_event',
    #     'user_id' => 'test_user',
    #     'user_properties' => { 'email' => 'test@test' },
    #     'event_properties' => { 'enum_properties' => 'test' }
    #   }
    #
    #   expect(event.event_body).to eq(expected_dict)
    # end

    it 'fails to set dictionary attributes with invalid values' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event['event_properties'] = { 4 => '4' }
      expect(event.event_properties).to be_falsey

      event['event_properties'] = { 'test' => ['4', [5, 6]] }
      expect(event.include?('event_properties')).to be_falsey

      event['event_properties'] = { 'test' => ['4', Set.new] }
      expect(event.include?('event_properties')).to be_falsey

      event['event_properties'] = { 'test' => EventOptions.new }
      expect(event.include?('event_properties')).to be_falsey
    end

    it 'successfully sets dictionary attributes with valid values' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      event['event_properties'] = { 'test' => ['4', { 'test' => true }] }
      expect(event.event_properties).to be_truthy
    end

    it 'truncates string attributes exceeding max length' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expected_event_body = { 'event_type' => 'test_event', 'user_id' => 'test_user' }
      long_str = 'acbdx' * 1000

      event['event_properties'] = { 'test_long_str' => long_str }
      expected_event_body['event_properties'] = { 'test_long_str' => long_str[0...MAX_STRING_LENGTH] }
      expect(event.event_body).to eq(expected_event_body)

      event['device_id'] = long_str
      expected_event_body['device_id'] = long_str[0...MAX_STRING_LENGTH]
      expect(event.event_body).to eq(expected_event_body)
    end

    it 'logs error when dictionary attributes exceed max key count' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expected_event_body = { 'event_type' => 'test_event', 'user_id' => 'test_user' }
      expected_event_body['event_properties'] = { 'test_max_key' => {} }
      event.event_properties = { 'test_max_key' => {} }
      logs_output = []
      allow(AmplitudeAnalytics.logger).to receive(:error) { |block| logs_output << block.to_s }
      (1...2000).each do |i|
        event.event_properties['test_max_key'][i] = 'test'
      end
      expect(event.event_body).to eq(expected_event_body)
      expect(logs_output).to include('Too many properties. 1024 maximum.')
    end

    it 'sets list attributes in dictionary attributes successfully' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expected_event_body = { 'event_type' => 'test_event', 'user_id' => 'test_user' }
      list_properties = ['a', 'c', 3, true]

      event['event_properties'] = { 'list_properties' => list_properties }
      expected_event_body['event_properties'] = { 'list_properties' => list_properties }
      expect(event.event_body).to eq(expected_event_body)
    end

    it 'sets boolean attributes in dictionary attributes successfully' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expected_event_body = { 'event_type' => 'test_event', 'user_id' => 'test_user' }
      bool_properties = false

      event['event_properties'] = { 'bool_properties' => bool_properties }
      expected_event_body['event_properties'] = { 'bool_properties' => bool_properties }
      expect(event.event_body).to eq(expected_event_body)
    end

    it 'sets numeric attributes in dictionary attributes successfully' do
      event = BaseEvent.new('test_event', user_id: 'test_user')
      expected_event_body = { 'event_type' => 'test_event', 'user_id' => 'test_user' }

      event['event_properties'] = { 'float_properties' => 26.92, 'int_properties' => 9 }
      expected_event_body['event_properties'] = { 'float_properties' => 26.92, 'int_properties' => 9 }
      expect(event.event_body).to eq(expected_event_body)
    end
  end
end
