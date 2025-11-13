module AmplitudeExperiment
  # Options for evaluating variants for a user.
  class EvaluateOptions
    attr_accessor :flag_keys, :tracks_exposure

    def initialize(flag_keys: nil, tracks_exposure: nil)
      @flag_keys = flag_keys
      @tracks_exposure = tracks_exposure
    end
  end
end
