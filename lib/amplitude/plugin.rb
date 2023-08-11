require 'securerandom'
module AmplitudeAnalytics
  # Plugin
  class Plugin
    attr_reader :plugin_type

    def initialize(plugin_type)
      @plugin_type = plugin_type
    end

    def setup(client)
      # Setup plugins with client instance parameter
    end

    def execute(event)
      # Process event with plugin instance
    end
  end

  # EventPlugin
  class EventPlugin < Plugin
    def execute(event)
      track(event)
    end

    def track(event)
      event
    end
  end

  # DestinationPlugin
  class DestinationPlugin < EventPlugin
    attr_reader :timeline

    def initialize
      super(PluginType::DESTINATION)
      @timeline = Timeline.new
    end

    def setup(client)
      @timeline.setup(client)
    end

    def add(plugin)
      @timeline.add(plugin)
      self
    end

    def remove(plugin)
      @timeline.remove(plugin)
      self
    end

    def execute(event)
      event = @timeline.process(event)
      super(event)
    end

    def shutdown
      @timeline.shutdown
    end
  end

  # AmplitudeDestinationPlugin
  class AmplitudeDestinationPlugin < DestinationPlugin
    def initialize
      super
      @workers = Workers.new
      @storage = nil
      @configuration = nil
    end

    def setup(client)
      super(client)
      @configuration = client.configuration
      @storage = client.configuration.storage
      @workers.setup(client.configuration, @storage)
      @storage.setup(client.configuration, @workers)
    end

    def verify_event(event)
      return false unless event.is_a?(BaseEvent) && event.event_type && (event.user_id || event.device_id)

      true
    end

    def execute(event)
      event = @timeline.process(event)
      raise 'Invalid event.' unless verify_event(event)

      @storage.push(event)
    end

    def flush
      @workers.flush
    end

    def shutdown
      @timeline.shutdown
      @workers.stop
    end
  end

  # ContextPlugin
  class ContextPlugin < Plugin
    attr_accessor :configuration

    def initialize
      super(PluginType::BEFORE)
      @context_string = "#{SDK_LIBRARY}/#{SDK_VERSION}"
      @configuration = nil
    end

    def setup(client)
      @configuration = client.configuration
    end

    def apply_context_data(event)
      event.library = @context_string
    end

    def execute(event)
      event.time ||= AmplitudeAnalytics.current_milliseconds
      event.insert_id ||= SecureRandom.uuid
      event.plan ||= @configuration.plan if @configuration.plan
      event.ingestion_metadata ||= @configuration.ingestion_metadata if @configuration.ingestion_metadata
      apply_context_data(event)
      event
    end
  end
end
