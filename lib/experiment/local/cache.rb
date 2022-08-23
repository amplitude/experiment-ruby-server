require 'uri'
require 'logger'

module AmplitudeExperiment
  # InMemoryFlagConfigCache
  # The place to store the flag configs fetched from the server
  class InMemoryFlagConfigCache
    attr_accessor :cache

    def initialize(flag_configs = {})
      @semaphore = Mutex.new
      @cache = flag_configs
    end

    def get(flag_key)
      @semaphore.synchronize do
        @cache.fetch(flag_key, nil)
      end
    end

    def caches
      @semaphore.synchronize do
        @cache
      end
    end

    def put(flag_key, flag_config)
      @semaphore.synchronize do
        @cache.store(flag_key, flag_config.clone)
      end
    end

    def put_all(flag_configs)
      @semaphore.synchronize do
        flag_configs.each do |key, value|
          @cache.store(key, value.clone) if value
        end
      end
    end

    def delete(flag_key)
      @semaphore.synchronize do
        @cache.delete(flag_key)
      end
    end

    def clear
      @semaphore.synchronize do
        @cache = {}
      end
    end
  end
end
