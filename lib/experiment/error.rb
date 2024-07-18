module AmplitudeExperiment
  # FetchError
  class FetchError < StandardError
    attr_reader :status_code

    def initialize(status_code, message)
      super(message)
      @status_code = status_code
    end
  end

  class CycleError < StandardError
    # Raised when topological sorting encounters a cycle between flag dependencies.
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_s
      "Detected a cycle between flags #{@path}"
    end
  end
end
