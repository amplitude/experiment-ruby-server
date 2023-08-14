require 'logger'
module AmplitudeAnalytics
  # Config
  class Config
    attr_accessor :api_key, :flush_interval_millis, :flush_max_retries,
                  :logger, :min_id_length, :callback, :server_zone, :use_batch,
                  :storage_provider, :opt_out, :plan, :ingestion_metadata

    def initialize(api_key: nil, flush_queue_size: FLUSH_QUEUE_SIZE,
                   flush_interval_millis: FLUSH_INTERVAL_MILLIS,
                   flush_max_retries: FLUSH_MAX_RETRIES,
                   logger: Logger.new($stdout, progname: LOGGER_NAME),
                   min_id_length: nil, callback: nil, server_zone: DEFAULT_ZONE,
                   use_batch: false, server_url: nil,
                   storage_provider: InMemoryStorageProvider.new, plan: nil, ingestion_metadata: nil)
      @api_key = api_key
      @flush_queue_size = flush_queue_size
      @flush_size_divider = 1
      @flush_interval_millis = flush_interval_millis
      @flush_max_retries = flush_max_retries
      @logger = logger
      @logger.progname = LOGGER_NAME
      @min_id_length = min_id_length
      @callback = callback
      @server_zone = server_zone
      @use_batch = use_batch
      @server_url = server_url
      @storage_provider = storage_provider
      @opt_out = false
      @plan = plan
      @ingestion_metadata = ingestion_metadata
    end

    def storage
      @storage_provider.storage
    end

    def valid?
      @api_key && @flush_queue_size > 0 && @flush_interval_millis > 0 && min_id_length_valid?
    end

    def min_id_length_valid?
      @min_id_length.nil? || (@min_id_length.is_a?(Integer) && @min_id_length > 0)
    end

    def flush_queue_size
      [@flush_queue_size / @flush_size_divider, 1].max
    end

    def flush_queue_size=(size)
      @flush_queue_size = size
      @flush_size_divider = 1
    end

    def server_url
      @url || (
        if use_batch
          SERVER_URL[@server_zone][BATCH]
        else
          SERVER_URL[@server_zone][HTTP_V2]
        end)
    end

    def server_url=(url)
      @url = url
    end

    def options
      { 'min_id_length' => @min_id_length } if min_id_length_valid? && @min_id_length
    end

    def increase_flush_divider
      @flush_size_divider += 1
    end

    def reset_flush_divider
      @flush_size_divider = 1
    end
  end
end
