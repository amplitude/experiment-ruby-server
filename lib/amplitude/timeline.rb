require_relative 'constants'

module AmplitudeAnalytics
  # Timeline
  class Timeline
    attr_accessor :configuration
    attr_reader :logger, :plugins

    def initialize(configuration = nil)
      @locks = {
        PluginType::BEFORE => Mutex.new,
        PluginType::ENRICHMENT => Mutex.new,
        PluginType::DESTINATION => Mutex.new
      }
      @plugins = {
        PluginType::BEFORE => [],
        PluginType::ENRICHMENT => [],
        PluginType::DESTINATION => []
      }
      @configuration = configuration
    end

    def setup(client)
      @configuration = client.configuration
    end

    def add(plugin)
      @locks[plugin.plugin_type].synchronize do
        @plugins[plugin.plugin_type] << plugin
      end
    end

    def remove(plugin)
      @locks.each_key do |plugin_type|
        @locks[plugin_type].synchronize do
          @plugins[plugin_type].reject! { |p| p == plugin }
        end
      end
    end

    def flush
      destination_futures = []
      @locks[PluginType::DESTINATION].synchronize do
        @plugins[PluginType::DESTINATION].each do |destination|
          destination_futures << destination.flush
        rescue StandardError
          @logger.exception('Error for flush events')
        end
      end
      destination_futures
    end

    def process(event)
      if @configuration&.opt_out
        @configuration.logger.info('Skipped event for opt out config')
        return event
      end

      before_result = apply_plugins(PluginType::BEFORE, event)
      enrich_result = apply_plugins(PluginType::ENRICHMENT, before_result)
      apply_plugins(PluginType::DESTINATION, enrich_result)

      enrich_result
    end

    def apply_plugins(plugin_type, event)
      result = event
      @locks[plugin_type].synchronize do
        @plugins[plugin_type].each do |plugin|
          break unless result

          begin
            if plugin.plugin_type == PluginType::DESTINATION
              plugin.execute(Marshal.load(Marshal.dump(result)))
            else
              result = plugin.execute(result)
            end
          rescue InvalidEventError
            @logger.error("Invalid event body #{event}")
          rescue StandardError
            @logger.error("Error for apply #{PluginType.name(plugin_type)} plugin for event #{event}")
          end
        end
      end
      result
    end

    def shutdown
      @locks[PluginType::DESTINATION].synchronize do
        @plugins[PluginType::DESTINATION].each(&:shutdown)
      end
    end
  end
end
