require 'spec_helper'

module AmplitudeExperiment
  describe InMemoryFlagConfigCache do
    config = LocalEvaluationConfig.new
    flag_config_cache = InMemoryFlagConfigCache.new(config.bootstrap)
    before(:each) do
      flag_config_cache.put('flag_key', { test: 'on' })
    end

    after(:each) do
      flag_config_cache.clear
    end

    describe '#get' do
      it 'get the flag config from cache with flag key' do
        test_flag_config = flag_config_cache.get('flag_key')
        expect(test_flag_config.to_json).to eq({ test: 'on' }.to_json)
      end
    end

    describe '#cache' do
      it 'get all flag configs from cache' do
        expect(flag_config_cache.cache.to_json).to eq({ flag_key: { test: 'on' } }.to_json)
      end
    end

    describe '#put' do
      it 'save the flag config into cache' do
        flag_config_cache.put('flag_key_two', { test: 'off' })
        expect(flag_config_cache.cache.to_json).to eq({ flag_key: { test: 'on' }, flag_key_two: { test: 'off' } }.to_json)
      end
    end

    describe '#put_all' do
      it 'put all flag configs into cache' do
        flag_configs = { flag_key_two: { test: 'off' }, flag_key_three: { test: 'switch' } }
        flag_config_cache.put_all(flag_configs)
        expect(flag_config_cache.cache.to_json).to eq({ flag_key: { test: 'on' }, flag_key_two: { test: 'off' }, flag_key_three: { test: 'switch' } }.to_json)
      end
    end

    describe '#clear' do
      it 'clear the flag config cache' do
        flag_config_cache.clear
        expect(flag_config_cache.cache.to_json).to eq({}.to_json)
      end
    end

    describe '#delete' do
      it 'delete flag config for the flag key from cache' do
        flag_config_cache.delete('flag_key')
        expect(flag_config_cache.cache.to_json).to eq({}.to_json)
      end
    end
  end
end
