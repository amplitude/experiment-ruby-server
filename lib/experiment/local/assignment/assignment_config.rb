module AmplitudeExperiment
  # AssignmentConfig
  class AssignmentConfig
    attr_accessor :api_key, :cache_capacity, :amp_config

    def initialize(api_key, cache_capacity = 65_536, amp_config: nil)
      @api_key = api_key
      @cache_capacity = cache_capacity
      @amp_config = amp_config
    end
  end
end
