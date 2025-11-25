require 'set'
module AmplitudeExperiment
  describe LocalEvaluationClient do
    let(:api_key) { 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3' }
    let(:test_user) { User.new(user_id: 'test_user') }
    let(:test_user2) { User.new(user_id: 'user_id', device_id: 'device_id') }

    def setup_stub
      response = '[{"key":"holdout-sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":1},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,429497],"variant":"holdout"},{"range":[429496,42949673],"variant":"on"}],"range":[0,100]}],"salt":"nI33zio8","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["42953"]},"value":"on"}}},{"key":"mutex-sdk-ci-local-dependencies-test-mutex","metadata":{"deployed":false,"evaluationMode":"local","flagType":"mutual-exclusion-group","flagVersion":1},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"slot-1"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"slot-1":{"key":"slot-1","payload":{"flagIds":["42953"]},"value":"slot-1"},"unallocated":{"key":"unallocated","payload":{"flagIds":[]},"value":"unallocated"}}},{"dependencies":["holdout-sdk-ci-local-dependencies-test-holdout","mutex-sdk-ci-local-dependencies-test-mutex"],"key":"sdk-ci-local-dependencies-test","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":9},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-local-dependencies-test-holdout","key"],"values":["on"]}],[{"op":"is not","selector":["result","mutex-sdk-ci-local-dependencies-test-mutex","key"],"values":["slot-1"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"sdk-local-evaluation-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":7},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"on"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":"payload","value":"on"}}},{"key":"holdout-sdk-ci-dependencies-test-force-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":2},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42520177],"variant":"holdout"},{"range":[42520175,42949673],"variant":"on"}],"range":[0,100]}],"salt":"ubvfZywq","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["44564"]},"value":"on"}}},{"dependencies":["holdout-sdk-ci-dependencies-test-force-holdout"],"key":"sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":5},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-dependencies-test-force-holdout","key"],"values":["on"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}}]'
      stub_request(:get, 'https://api.lab.amplitude.com/sdk/v2/flags?v=0')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => "Api-Key #{api_key}",
            'Content-Type' => 'application/json;charset=utf-8',
            'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}",
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: response, headers: {})
    end

    describe '#initialize' do
      it 'error if api_key is nil' do
        expect { LocalEvaluationClient.new(nil) }.to raise_error(ArgumentError)
      end

      it 'error if api_key is empty' do
        expect { LocalEvaluationClient.new('') }.to raise_error(ArgumentError)
      end

      it 'uses custom logger when provided' do
        custom_logger = Logger.new($stdout)
        config = LocalEvaluationConfig.new(logger: custom_logger)
        client = LocalEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger)).to eq(custom_logger)
      end

      it 'debug flag overrides logger level to DEBUG when not provided a custom logger ' do
        config = LocalEvaluationConfig.new(debug: true)
        client = LocalEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger).level).to eq(Logger::DEBUG)
      end

      it 'debug flag does not modify logger level when provided a custom logger' do
        custom_logger = Logger.new($stdout)
        custom_logger.level = Logger::WARN
        config = LocalEvaluationConfig.new(logger: custom_logger, debug: true)
        client = LocalEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger).level).to eq(Logger::WARN)
      end
    end

    describe '#evaluation' do
      it 'evaluation should return specific variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(test_user, ['sdk-local-evaluation-ci-test'])
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new(key: 'on', value: 'on', payload: 'payload'))
      end

      it 'evaluation should return all variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(test_user)
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new(key: 'on', value: 'on', payload: 'payload'))
      end

      it 'evaluation with dependencies should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2)
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new(key: 'control', value: 'control'))
      end

      it 'evaluation with dependencies and flag keys should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2, ['sdk-ci-local-dependencies-test'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new(key: 'control', value: 'control'))
      end

      it 'evaluation with dependencies and flag keys not existing should not return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2, ['does-not-exist'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(nil)
      end

      it 'evaluation with dependencies holdout excludes variant from experiment' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2)
        expect(result['sdk-ci-local-dependencies-test-holdout']).to eq(nil)
      end

      it 'evaluate_v2 with tracks_exposure tracks non-default variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key, LocalEvaluationConfig.new(exposure_config: ExposureConfig.new('api_key')))
        local_evaluation_client.start

        # Mock the amplitude client's track method
        mock_amplitude = local_evaluation_client.instance_variable_get(:@exposure_service).instance_variable_get(:@amplitude)
        tracked_events = []
        allow(mock_amplitude).to receive(:track) do |event|
          tracked_events << event
        end

        # Perform evaluation with tracks_exposure=true
        options = EvaluateOptions.new(tracks_exposure: true)
        variants = local_evaluation_client.evaluate_v2(test_user, ['sdk-local-evaluation-ci-test'], options)

        # Verify that track was called
        expect(tracked_events.length).to be > 0, 'Amplitude track should be called when tracks_exposure is true'

        # Count non-default variants
        non_default_variants = variants.reject do |_flag_key, variant|
          (variant.metadata && variant.metadata['default'])
        end

        # Verify that we have one event per non-default variant
        expect(tracked_events.length).to eq(non_default_variants.length),
                                         "Expected #{non_default_variants.length} exposure events, got #{tracked_events.length}"

        # Verify each event has the correct structure
        tracked_flag_keys = Set.new
        tracked_events.each do |event|
          expect(event.event_type).to eq('[Experiment] Exposure')
          expect(event.user_id).to eq(test_user.user_id)
          flag_key = event.event_properties['[Experiment] Flag Key']
          expect(flag_key).not_to be_nil, 'Event should have flag key'
          tracked_flag_keys.add(flag_key)
          # Verify the variant is not default
          variant = variants[flag_key]
          expect(variant).not_to be_nil, "Variant for #{flag_key} should exist"
          expect(variant.metadata && variant.metadata['default']).to be_falsy,
                                                                     "Variant for #{flag_key} should not be default"
        end

        # Verify all non-default variants were tracked
        expect(tracked_flag_keys).to eq(Set.new(non_default_variants.keys)),
                                     'All non-default variants should be tracked'
      end
    end
  end
end
