module AmplitudeAnalytics
  SDK_LIBRARY = 'amplitude-experiment-ruby'.freeze
  SDK_VERSION = '1.1.5'.freeze

  EU_ZONE = 'EU'.freeze
  DEFAULT_ZONE = 'US'.freeze
  BATCH = 'batch'.freeze
  HTTP_V2 = 'v2'.freeze
  SERVER_URL = {
    EU_ZONE => {
      BATCH => 'https://api.eu.amplitude.com/batch',
      HTTP_V2 => 'https://api.eu.amplitude.com/2/httpapi'
    },
    DEFAULT_ZONE => {
      BATCH => 'https://api2.amplitude.com/batch',
      HTTP_V2 => 'https://api2.amplitude.com/2/httpapi'
    }
  }.freeze
  LOGGER_NAME = 'amplitude'.freeze

  MAX_PROPERTY_KEYS = 1024
  MAX_STRING_LENGTH = 1024
  FLUSH_QUEUE_SIZE = 200
  FLUSH_INTERVAL_MILLIS = 10_000
  FLUSH_MAX_RETRIES = 12
  CONNECTION_TIMEOUT = 10.0 # seconds float
  MAX_BUFFER_CAPACITY = 20_000

  # PluginType
  class PluginType
    BEFORE = 0
    ENRICHMENT = 1
    DESTINATION = 2
    OBSERVE = 3

    def self.name(value)
      mapping = {
        BEFORE => 'BEFORE',
        ENRICHMENT => 'ENRICHMENT',
        DESTINATION => 'DESTINATION',
        OBSERVE => 'OBSERVE'
      }

      mapping[value]
    end
  end
end
