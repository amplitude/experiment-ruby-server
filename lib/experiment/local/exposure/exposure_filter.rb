module AmplitudeExperiment
  # ExposureFilter
  class ExposureFilter
    def initialize(size, ttl_millis = DAY_MILLIS)
      @cache = LRUCache.new(size, ttl_millis)
      @ttl_millis = ttl_millis
    end

    def should_track(exposure)
      return false if exposure.results.empty?

      canonical_exposure = exposure.canonicalize
      track = @cache.get(canonical_exposure).nil?
      @cache.put(canonical_exposure, 0) if track
      track
    end
  end
end
