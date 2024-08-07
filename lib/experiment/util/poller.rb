module AmplitudeExperiment
  # Poller
  class Poller
    def initialize(interval_seconds, callback)
      @interval_seconds = interval_seconds
      @callback = callback
    end

    def start
      @running = true
      @thread = Thread.new do
        while @running
          @callback.call
          sleep(@interval_seconds)
        end
      end
    end

    def stop
      @running = false
      @thread&.join
    end
  end
end
