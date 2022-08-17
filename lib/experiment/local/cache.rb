require 'uri'
require 'logger'

module AmplitudeExperiment
  # Main client for fetching variant data.
  class InMemoryFlagConfigCache
    attr_accessor :cache

    def initialize(flag_configs = {})
      @cache = flag_configs
    end

    def get(flag_key)
      @cache.fetch(flag_key, nil)
    end

    def caches
      @cache
    end

    def put(flag_key, flag_config)
      @cache.store(flag_key, flag_config.clone)
    end

    def put_all(flag_configs)
      flag_configs.each do |key, value|
        @cache.store(key, value.clone) if value
      end
    end

    def delete(flag_key)
      @cache.delete(flag_key)
    end

    def clear
      @cache = {}
    end
  end
end
