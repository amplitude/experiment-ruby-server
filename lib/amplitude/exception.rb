module AmplitudeAnalytics
  # InvalidEventError
  class InvalidEventError < StandardError
    def initialize(message = 'Invalid event.')
      super(message)
    end
  end

  # InvalidAPIKeyError
  class InvalidAPIKeyError < StandardError
    def initialize(message = 'Invalid API key.')
      super(message)
    end
  end
end
