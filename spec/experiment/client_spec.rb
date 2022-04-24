require 'spec_helper'

module Experiment
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

    describe '#fetch' do
      before do
        allow(Thread).to receive(:new).and_yield
      end

      it 'fetch success' do
        stub_request(:post, SERVER_URL)
          .to_return(status: 200, body: '{"sdk-ci-test":{"key":"on","payload":"payload"}}')
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(debug: true))
        expected_variant = Variant.new('on', 'payload')
        variants = client.fetch(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants.fetch('sdk-ci-test')).to eq(expected_variant)
        end
        expect(variants.key?('sdk-ci-test')).to be_truthy
        expect(variants.fetch('sdk-ci-test')).to eq(expected_variant)
      end

      it 'fetch success with value format' do
        stub_request(:post, SERVER_URL)
          .to_return(status: 200, body: '{"sdk-ci-test":{"value":"on","payload":"payload"}}')
        test_user = User.new(user_id: 'test_user', device_id: 'a4edba84-dba0-405c-be9c-7ce580cb83f3', country: 'US',
                             city: 'San Francisco', region: 'California', language: 'English', platform: 'server',
                             version: '1.0.0', device_brand: 'Google', carrier: 'Verizon',
                             user_properties: {
                               'test_user_property' => 'test value' * 1000
                             })
        client = Client.new(API_KEY)
        expected_variant = Variant.new('on', 'payload')
        variants = client.fetch(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants.fetch('sdk-ci-test')).to eq(expected_variant)
        end
        expect(variants.key?('sdk-ci-test')).to be_truthy
        expect(variants.fetch('sdk-ci-test')).to eq(expected_variant)
      end

      it 'fetch timeout failure, no retries' do
        stub_request(:post, SERVER_URL)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(fetch_timeout_millis: 1, fetch_retries: 0))
        variants = client.fetch(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants).to eq({})
        end
        expect(variants).to eq({})
      end

      it 'fetch with retries' do
        stub_request(:post, SERVER_URL)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(fetch_timeout_millis: 1, fetch_retries: 1, debug: true))
        variants = client.fetch(test_user) do |user, block_variants|
          expect(user).to equal(test_user)
          expect(block_variants).to eq({})
        end
        expect(variants).to eq({})
      end
    end
  end
end
