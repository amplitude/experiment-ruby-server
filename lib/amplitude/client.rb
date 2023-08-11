module AmplitudeAnalytics
  # Amplitude
  class Amplitude
    attr_reader :configuration, :timeline

    def initialize(api_key, configuration: Config.new)
      @configuration = configuration
      @configuration.api_key = api_key
      @timeline = Timeline.new
      @timeline.setup(self)
      register_on_exit
      add(AmplitudeDestinationPlugin.new)
      add(ContextPlugin.new)
    end

    def track(event)
      @timeline.process(event)
    end

    def flush
      @timeline.flush
    end

    def add(plugin)
      @timeline.add(plugin)
      plugin.setup(self)
      self
    end

    def remove(plugin)
      @timeline.remove(plugin)
      self
    end

    def shutdown
      @configuration.opt_out = true
      @timeline.shutdown
    end

    private

    def register_on_exit
      if Thread.respond_to?(:_at_exit)
        begin
          at_exit { method(:shutdown) }
        rescue StandardError
          @configuration.logger.warning('register for exit fail')
        end
      else
        at_exit { shutdown }
      end
    end
  end
end
