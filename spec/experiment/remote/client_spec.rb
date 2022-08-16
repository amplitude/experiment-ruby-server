require 'spec_helper'

module AmplitudeExperiment
  API_KEY = 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3'.freeze
  SERVER_URL = 'https://api.lab.amplitude.com/sdk/vardata'.freeze

  describe Client do
    describe '#initialize' do
      it 'error if api_key is nil' do
        expect { Client.new(nil) }.to raise_error(ArgumentError)
      end

      it 'error if api_key is empty' do
        expect { Client.new('') }.to raise_error(ArgumentError)
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
    test_user =  User.new(user_id: 'test_user')
    test_user_with_properties = User.new(user_id: 'test_user', device_id: 'a4edba84-dba0-405c-be9c-7ce580cb83f3', country: 'US',
                                         city: 'San Francisco', region: 'California', language: 'English', platform: 'server',
                                         version: '1.0.0', device_brand: 'Google', carrier: 'Verizon',
                                         user_properties: {
                                           'test_user_property' => 'test value' * 1000
                                         })

    describe '#fetch' do
      def self.test_fetch(response, test_user, variant_name, debug, expected_state, expected_payload)
        it "fetch sync success with response #{response}, user #{test_user.user_id}, debug #{debug}" do
          stub_request(:post, SERVER_URL)
            .to_return(status: 200, body: response)
          client = Client.new(API_KEY, Config.new(debug: debug))
          expected_variant = Variant.new(expected_state, expected_payload)
          variants = client.fetch(test_user)
          expect(variants.key?(variant_name)).to be_truthy
          expect(variants.fetch(variant_name)).to eq(expected_variant)
        end
      end

      test_fetch response_with_key, test_user, variant_name, false, 'on', 'payload'
      test_fetch response_with_value, test_user_with_properties, variant_name, false, 'on', 'payload'
      test_fetch response_with_int_payload, test_user, variant_name, true, 'off', 123
      test_fetch response_with_boolean_payload, test_user_with_properties, variant_name, false, 'on', false
      test_fetch response_with_list_payload, test_user, variant_name, false, 'on', %w[payload1 payload2]
      test_fetch response_with_hash_payload, test_user_with_properties, variant_name, false, 'off', { 'nested' => 'nested payload' }
      test_fetch response_without_payload, test_user, variant_name, false, 'on', nil
      test_fetch response_with_value_without_payload, test_user, variant_name, false, 'on', nil

      it 'fetch timeout failure' do
        stub_request(:post, SERVER_URL)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = nil
        expect { variants = client.fetch(test_user) }.to output(/Retrying fetch/).to_stdout_from_any_process
        expect(variants).to eq({})
      end
    end

    describe '#fetch_async' do
      before do
        allow(Thread).to receive(:new).and_yield
      end

      def self.test_fetch_async(response, test_user, variant_name, debug, expected_state, expected_payload)
        it "fetch async success with response #{response}, user #{test_user.user_id}, debug #{debug}" do
          stub_request(:post, SERVER_URL)
            .to_return(status: 200, body: response)
          client = Client.new(API_KEY, Config.new(debug: debug))
          expected_variant = Variant.new(expected_state, expected_payload)
          variants = client.fetch_async(test_user) do |user, block_variants|
            expect(user).to equal(test_user)
            expect(block_variants.fetch(variant_name)).to eq(expected_variant)
          end
          expect(variants.key?(variant_name)).to be_truthy
          expect(variants.fetch(variant_name)).to eq(expected_variant)
        end
      end

      test_fetch_async response_with_key, test_user, variant_name, false, 'on', 'payload'
      test_fetch_async response_with_value, test_user_with_properties, variant_name, false, 'on', 'payload'
      test_fetch_async response_with_int_payload, test_user, variant_name, true, 'off', 123
      test_fetch_async response_with_boolean_payload, test_user_with_properties, variant_name, false, 'on', false
      test_fetch_async response_with_list_payload, test_user, variant_name, false, 'on', %w[payload1 payload2]
      test_fetch_async response_with_hash_payload, test_user_with_properties, variant_name, false, 'off', { 'nested' => 'nested payload' }
      test_fetch_async response_without_payload, test_user, variant_name, false, 'on', nil
      test_fetch_async response_with_value_without_payload, test_user, variant_name, false, 'on', nil

      it 'fetch async timeout failure' do
        stub_request(:post, SERVER_URL)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = client.fetch_async(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants).to eq({})
        end
        expect(variants).to eq({})
      end
    end
  end
end
