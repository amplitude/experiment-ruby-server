module AmplitudeExperiment
  describe RemoteEvaluationClient do
    let(:api_key) { 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3' }
    let(:server_url) { 'https://api.lab.amplitude.com/sdk/v2/vardata?v=0' }

    describe '#initialize' do
      it 'raises an error if api_key is nil' do
        expect { RemoteEvaluationClient.new(nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error if api_key is empty' do
        expect { RemoteEvaluationClient.new('') }.to raise_error(ArgumentError)
      end

      it 'uses custom logger when provided' do
        custom_logger = Logger.new($stdout)
        config = RemoteEvaluationConfig.new(logger: custom_logger)
        client = RemoteEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger)).to eq(custom_logger)
      end

      it 'debug flag overrides logger level to DEBUG when not provided a custom logger ' do
        config = RemoteEvaluationConfig.new(debug: true)
        client = RemoteEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger).level).to eq(Logger::DEBUG)
      end

      it 'debug flag does not modify logger level when provided a custom logger' do
        custom_logger = Logger.new($stdout)
        custom_logger.level = Logger::WARN
        config = RemoteEvaluationConfig.new(logger: custom_logger, debug: true)
        client = RemoteEvaluationClient.new(api_key, config)

        expect(client.instance_variable_get(:@logger).level).to eq(Logger::WARN)
      end
    end

    response_with_key = '{"sdk-ci-test":{"key":"on","payload":"payload"}}'
    response_with_value = '{"sdk-ci-test":{"value":"on","payload":"payload"}}'
    response_with_boolean_payload = '{"sdk-ci-test":{"key":"on","payload":false}}'
    response_with_int_payload = '{"sdk-ci-test":{"key":"off","payload":123}}'
    response_with_list_payload = '{"sdk-ci-test":{"key":"on","payload":["payload1", "payload2"]}}'
    response_with_hash_payload = '{"sdk-ci-test":{"key":"off","payload":{"nested": "nested payload"}}}'
    response_without_payload = '{"sdk-ci-test":{"key":"on"}}'
    response_with_value_without_payload = '{"sdk-ci-test":{"value":"on"}}'
    variant_name = 'sdk-ci-test'
    test_user = User.new(user_id: 'test_user')
    test_user_with_properties = User.new(user_id: 'test_user', device_id: 'a4edba84-dba0-405c-be9c-7ce580cb83f3', country: 'US',
                                         city: 'San Francisco', region: 'California', language: 'English', platform: 'server',
                                         version: '1.0.0', device_brand: 'Google', carrier: 'Verizon',
                                         user_properties: {
                                           'test_user_property' => 'test value' * 1000
                                         })

    def self.test_fetch_shared(response, test_user, variant_name, debug, expected_variant)
      it "fetch sync success with response #{response}, user #{test_user.user_id}, debug #{debug}" do
        stub_request(:post, server_url)
          .to_return(status: 200, body: response)
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(debug: debug))
        variants = client.fetch(test_user)
        expect(variants.key?(variant_name)).to be_truthy
        expect(variants.fetch(variant_name)).to eq(expected_variant)
      end
    end

    def self.test_fetch_v2_shared(response, test_user, variant_name, debug, expected_variant)
      it "fetch v2 sync success with response #{response}, user #{test_user.user_id}, debug #{debug}" do
        stub_request(:post, server_url)
          .to_return(status: 200, body: response)
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(debug: debug))
        variants = client.fetch_v2(test_user)
        expect(variants.key?(variant_name)).to be_truthy
        expect(variants.fetch(variant_name)).to eq(expected_variant)
      end
    end

    describe '#fetch' do
      test_fetch_shared response_with_key, test_user, variant_name, false, Variant.new(payload: 'payload', key: 'on')
      test_fetch_shared response_with_value, test_user_with_properties, variant_name, false, Variant.new(value: 'on', payload: 'payload')
      test_fetch_shared response_with_int_payload, test_user, variant_name, true, Variant.new(payload: 123, key: 'off')
      test_fetch_shared response_with_boolean_payload, test_user_with_properties, variant_name, false, Variant.new(payload: false, key: 'on')
      test_fetch_shared response_with_list_payload, test_user, variant_name, false, Variant.new(payload: %w[payload1 payload2], key: 'on')
      test_fetch_shared response_with_hash_payload, test_user_with_properties, variant_name, false, Variant.new(payload: { 'nested' => 'nested payload' }, key: 'off')
      test_fetch_shared response_without_payload, test_user, variant_name, false, Variant.new(key: 'on')
      test_fetch_shared response_with_value_without_payload, test_user, variant_name, false, Variant.new(value: 'on')

      it 'open timeout failure' do
        stub_request(:post, server_url)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(connect_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = nil
        expect { variants = client.fetch(test_user) }.to output(/Retrying fetch/).to_stdout_from_any_process
        expect(variants).to eq({})
      end

      it 'fetch timeout failure' do
        stub_request(:post, server_url)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = nil
        expect { variants = client.fetch(test_user) }.to output(/Retrying fetch/).to_stdout_from_any_process
        expect(variants).to eq({})
      end
    end

    describe '#fetch_async' do
      before do
        allow(Thread).to receive(:new).and_yield
      end

      def self.test_fetch_async_shared(response, test_user, variant_name, debug, expected_variant)
        it "fetch async success with response #{response}, user #{test_user.user_id}, debug #{debug}" do
          stub_request(:post, server_url)
            .to_return(status: 200, body: response)
          client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(debug: debug))
          callback_called = false
          variants = client.fetch_async(test_user) do |user, block_variants|
            expect(user).to equal(test_user)
            expect(block_variants.fetch(variant_name)).to eq(expected_variant)
            callback_called = true
          end
          sleep 1 until callback_called
          expect(variants.key?(variant_name)).to be_truthy
          expect(variants.fetch(variant_name)).to eq(expected_variant)
        end
      end

      test_fetch_async_shared response_with_key, test_user, variant_name, false, Variant.new(payload: 'payload', key: 'on')
      test_fetch_async_shared response_with_value, test_user_with_properties, variant_name, false, Variant.new(value: 'on', payload: 'payload')
      test_fetch_async_shared response_with_int_payload, test_user, variant_name, true, Variant.new(payload: 123, key: 'off')
      test_fetch_async_shared response_with_boolean_payload, test_user_with_properties, variant_name, false, Variant.new(payload: false, key: 'on')
      test_fetch_async_shared response_with_list_payload, test_user, variant_name, false, Variant.new(payload: %w[payload1 payload2], key: 'on')
      test_fetch_async_shared response_with_hash_payload, test_user_with_properties, variant_name, false, Variant.new(payload: { 'nested' => 'nested payload' }, key: 'off')
      test_fetch_async_shared response_without_payload, test_user, variant_name, false, Variant.new(key: 'on')
      test_fetch_async_shared response_with_value_without_payload, test_user, variant_name, false, Variant.new(value: 'on')

      it 'fetch async timeout failure' do
        stub_request(:post, server_url)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = client.fetch_async(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants).to eq({})
        end
        expect(variants).to eq({})
      end

      context 'fetch retry with different response codes' do
        [
          [300, 'Fetch Exception 300', true],
          [400, 'Fetch Exception 400', false],
          [429, 'Fetch Exception 429', true],
          [500, 'Fetch Exception 500', true],
          [0, 'Other Exception', true]
        ].each do |response_code, error_message, should_call_retry|
          it "handles response code #{response_code}" do
            client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(fetch_retries: 1))
            allow(client).to receive(:retry_fetch)
            allow(client).to receive(:do_fetch) do
              response_code == 0 ? raise(StandardError, error_message) : raise(FetchError.new(response_code, error_message))
            end
            expect(client).to receive(:do_fetch)
            expect(client).to receive(:retry_fetch) if should_call_retry
            user = User.new(user_id: 'test_user')
            client.fetch(user)
          end
        end
      end
    end

    describe '#fetch_v2' do
      test_fetch_v2_shared response_with_key, test_user, variant_name, false, Variant.new(key: 'on', payload: 'payload')
      test_fetch_v2_shared response_with_value, test_user_with_properties, variant_name, false, Variant.new(payload: 'payload', value: 'on')
      test_fetch_v2_shared response_with_int_payload, test_user, variant_name, true, Variant.new(key: 'off', payload: 123)
      test_fetch_v2_shared response_with_boolean_payload, test_user_with_properties, variant_name, false, Variant.new(key: 'on', payload: false)
      test_fetch_v2_shared response_with_list_payload, test_user, variant_name, false, Variant.new(key: 'on', payload: %w[payload1 payload2])
      test_fetch_v2_shared response_with_hash_payload, test_user_with_properties, variant_name, false, Variant.new(key: 'off', payload: { 'nested' => 'nested payload' })
      test_fetch_v2_shared response_without_payload, test_user, variant_name, false, Variant.new(key: 'on')
      test_fetch_v2_shared response_with_value_without_payload, test_user, variant_name, false, Variant.new(value: 'on')

      it 'fetch v2 open timeout failure' do
        stub_request(:post, server_url)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(connect_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = nil
        expect { variants = client.fetch_v2(test_user) }.to output(/Retrying fetch/).to_stdout_from_any_process
        expect(variants).to eq({})
      end

      it 'fetch v2 timeout failure' do
        stub_request(:post, server_url)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = nil
        expect { variants = client.fetch_v2(test_user) }.to output(/Retrying fetch/).to_stdout_from_any_process
        expect(variants).to eq({})
      end

      it 'fetch v2 with fetch options' do
        stub_request(:post, server_url)
          .to_return(status: 200, body: response_with_key)
        test_user = User.new(user_id: 'test_user')
        client = RemoteEvaluationClient.new(api_key)

        WebMock.reset!
        fetch_options = FetchOptions.new(tracks_assignment: true, tracks_exposure: true)
        variants = client.fetch_v2(test_user, fetch_options)
        expect(variants.key?(variant_name)).to be_truthy
        expect(variants.fetch(variant_name)).to eq(Variant.new(key: 'on', payload: 'payload', value: 'on'))

        expect(a_request(:post, server_url).with(headers: { 'X-Amp-Exp-Track' => 'track', 'X-Amp-Exp-Exposure-Track' => 'track' })).to have_been_made.once

        WebMock.reset!
        fetch_options = FetchOptions.new(tracks_assignment: false, tracks_exposure: false)
        client.fetch_v2(test_user, fetch_options)
        expect(a_request(:post, server_url).with(headers: { 'X-Amp-Exp-Track' => 'no-track', 'X-Amp-Exp-Exposure-Track' => 'no-track' })).to have_been_made.once

        WebMock.reset!
        last_request = nil
        WebMock.after_request { |request_signature, _response| last_request = request_signature }
        fetch_options = FetchOptions.new
        client.fetch_v2(test_user, fetch_options)
        expect(a_request(:post, server_url)).to have_been_made.once
        expect(last_request.headers.key?('X-Amp-Exp-Track')).to be_falsy
        expect(last_request.headers.key?('X-Amp-Exp-Exposure-Track')).to be_falsy
      end
    end

    describe '#fetch_async_v2' do
      it 'fetch async v2 with fetch options' do
        stub_request(:post, server_url)
          .to_return(status: 200, body: response_with_key)
        test_user = User.new(user_id: 'test_user')
        fetch_options = FetchOptions.new(tracks_assignment: true, tracks_exposure: true)
        client = RemoteEvaluationClient.new(api_key, RemoteEvaluationConfig.new(debug: true))
        callback_called = false
        client.fetch_async_v2(test_user, fetch_options) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants.key?(variant_name)).to be_truthy
          expect(block_variants.fetch(variant_name)).to eq(Variant.new(key: 'on', payload: 'payload'))
          expect(a_request(:post, server_url).with(headers: { 'X-Amp-Exp-Track' => 'track', 'X-Amp-Exp-Exposure-Track' => 'track' })).to have_been_made.once
          callback_called = true
        end
        sleep 1 until callback_called
      end
    end
  end
end
