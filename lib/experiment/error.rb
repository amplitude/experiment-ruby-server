module AmplitudeExperiment
  # FetchError
  class FetchError < StandardError
    attr_reader :status_code

    def initialize(status_code, message)
      super(message)
      @status_code = status_code
    end
  end

  class CohortDownloadError < StandardError
    attr_reader :cohort_id

    def initialize(cohort_id, message)
      super(message)
      @cohort_id = cohort_id
    end
  end

  # CohortTooLargeError
  class CohortTooLargeError < CohortDownloadError
  end

  # HTTPErrorResponseError
  class HTTPErrorResponseError < CohortDownloadError
    attr_reader :status_code

    def initialize(status_code, cohort_id, message)
      super(cohort_id, message)
      @status_code = status_code
    end
  end
end
