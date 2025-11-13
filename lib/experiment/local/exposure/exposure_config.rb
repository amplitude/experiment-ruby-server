module AmplitudeExperiment
  # ExposureConfig
  class ExposureConfig < AmplitudeAnalytics::Config
    attr_accessor :api_key, :cache_capacity

    def initialize(api_key = nil, cache_capacity = 65_536, **kwargs)
      super(**kwargs)
      @api_key = api_key
      @cache_capacity = cache_capacity
    end
  end
end
