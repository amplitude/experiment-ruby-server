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

  # CohortNotModifiedError
  class CohortNotModifiedError < CohortDownloadError
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

  # CohortUpdateError
  class CohortUpdateError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(to_s)
    end

    def to_s
      error_messages = @errors.map do |item|
        if item.is_a?(Array) && item.size == 2
          cohort_id, error = item
          "Cohort #{cohort_id}: #{error}"
        else
          item.to_s
        end
      end
      "#{@errors.length} cohort(s) failed to update:\n#{error_messages.join("\n")}"
    end
  end

  class CycleError < StandardError
    # Raised when topological sorting encounters a cycle between flag dependencies.
    attr_reader :path

    def initialize(path)
      super
      @path = path
    end

    def to_s
      "Detected a cycle between flags #{@path}"
    end
  end
end
