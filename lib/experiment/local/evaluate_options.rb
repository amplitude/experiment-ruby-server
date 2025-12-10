module AmplitudeExperiment
  # Options for evaluating variants for a user.
  class EvaluateOptions
    attr_accessor :tracks_exposure

    def initialize(tracks_exposure: nil)
      @tracks_exposure = tracks_exposure
    end
  end
end
