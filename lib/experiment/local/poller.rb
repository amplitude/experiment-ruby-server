module AmplitudeExperiment
  # LocalEvaluationConfig
  # update the flag_config cache value
  class FlagConfigPoller
    FLAG_CONFIG_POLLING_INTERVAL_MILLIS = 30_000

    def initialize(fetcher, cache, debug, poll_interval_millis: FLAG_CONFIG_POLLING_INTERVAL_MILLIS)
      @fetcher = fetcher
      @cache = cache
      @poll_interval_millis = poll_interval_millis
      @logger = Logger.new($stdout)
      @debug = debug
      @poller_thread = nil
      @is_running = false

    end

    # Fetch initial flag configurations and start polling for updates.
    # You must call this function to begin polling for flag config updates.
    # Calling this function while the poller is already running does nothing.
    def start
      return if @is_running

      @logger.debug('[Experiment] poller - start') if @debug
      run
    end

    # Stop polling for flag configurations.
    # Calling this function while the poller is not running will do nothing.
    def stop
      @poller_thread&.exit
      @is_running = false
      @poller_thread = nil
    end

    private

    def run
      @is_running = true
      flag_configs = @fetcher.fetch
      @cache.clear
      @cache.put_all(flag_configs)
      @poller_thread = Thread.new do
        sleep @poll_interval_millis
        run
      end
    end
  end
end
