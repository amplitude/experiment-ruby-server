module AmplitudeExperiment
  # FetchError
  class FetchError < StandardError
    attr_reader :status_code

    def initialize(message, status_code)
      super(message)
      @status_code = status_code
    end
  end
end
