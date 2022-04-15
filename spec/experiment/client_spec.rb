require 'webmock/rspec'
require_relative '../../lib/experiment/client'
require_relative '../../lib/experiment/user'
require_relative '../../lib/experiment/variant'

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
        client = Client.new(API_KEY)
        variants = client.fetch(test_user)
        expected_variant = Variant.new('on', 'payload')
        expect(variants.key?('sdk-ci-test')).to be_truthy
        expect(variants.fetch('sdk-ci-test')).to eq(expected_variant)
      end

      it 'fetch timeout failure, no retries' do
        stub_request(:post, SERVER_URL)
          .to_timeout
        test_user = User.new(user_id: 'test_user')
        client = Client.new(API_KEY, Config.new(fetch_timeout_millis: 1, fetch_retries: 0))
        variants = client.fetch(test_user)
        expect(variants).to eq({})
      end
    end
  end
end
