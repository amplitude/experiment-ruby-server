module AmplitudeExperiment
  # FlagConfigStorage
  class FlagConfigStorage
    def flag_config(key)
      raise NotImplementedError
    end

    def flag_configs
      raise NotImplementedError
    end

    def put_flag_config(flag_config)
      raise NotImplementedError
    end

    def remove_if(&condition)
      raise NotImplementedError
    end
  end

  # InMemoryFlagConfigStorage
  class InMemoryFlagConfigStorage < FlagConfigStorage
    def initialize
      super # Call the parent class's constructor with no arguments
      @flag_configs = {}
      @flag_configs_lock = Mutex.new
    end

    def flag_config(key)
      @flag_configs_lock.synchronize do
        @flag_configs[key]
      end
    end

    def flag_configs
      @flag_configs_lock.synchronize do
        @flag_configs.dup
      end
    end

    def put_flag_config(flag_config)
      @flag_configs_lock.synchronize do
        @flag_configs[flag_config['key']] = flag_config
      end
    end

    def remove_if
      @flag_configs_lock.synchronize do
        @flag_configs.delete_if { |_key, value| yield(value) }
      end
    end
  end
end
