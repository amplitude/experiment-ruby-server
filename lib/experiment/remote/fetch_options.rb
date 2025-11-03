module AmplitudeExperiment
  # Fetch options
  class FetchOptions
    # Whether to track assignment events.
    # @return [Boolean, nil] the value of tracks_assignment
    attr_accessor :tracks_assignment

    # Whether to track exposure events.
    # @return [Boolean, nil] the value of tracks_exposure
    attr_accessor :tracks_exposure

    def initialize(tracks_assignment: nil, tracks_exposure: nil)
      @tracks_assignment = tracks_assignment
      @tracks_exposure = tracks_exposure
    end
  end
end
