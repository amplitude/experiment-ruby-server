module AmplitudeExperiment
  # AssignmentFilter
  class AssignmentFilter

    def initialize(size, ttl_millis = DAY_MILLIS)
      @cache = LRUCache.new(size, ttl_millis)
    end

    def should_track(assignment)
      canonical_assignment = assignment.canonicalize
      track = @cache.get(canonical_assignment).nil?
      @cache.put(canonical_assignment, 0) if track
      track
    end
  end
end
