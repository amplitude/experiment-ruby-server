module AmplitudeExperiment
  # AssignmentConfig
  class AssignmentConfig < AmplitudeAnalytics::Config
    attr_accessor :api_key, :cache_capacity

    def initialize(api_key, cache_capacity = 65_536, **kwargs)
      @api_key = api_key
      @cache_capacity = cache_capacity
      super(**kwargs)
    end
  end
end
