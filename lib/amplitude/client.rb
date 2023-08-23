module AmplitudeAnalytics
  # Amplitude
  class Amplitude
    attr_reader :configuration, :timeline

    def initialize(api_key, configuration: nil)
      @configuration = configuration || Config.new
      @configuration.api_key = api_key
      @timeline = Timeline.new
      @timeline.setup(self)
      add(AmplitudeDestinationPlugin.new)
      add(ContextPlugin.new)
      register_on_exit
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
          at_exit { shutdown }
        rescue StandardError
          @configuration.logger.warning('register for exit fail')
        end
      else
        at_exit { shutdown }
      end
    end
  end
end
