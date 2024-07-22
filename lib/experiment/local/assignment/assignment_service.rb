require_relative '../../../amplitude'
module AmplitudeExperiment
  class AssignmentService
    def initialize(amplitude, assignment_filter)
      @amplitude = amplitude
      @assignment_filter = assignment_filter
    end

    def track(assignment)
      @amplitude.track(AssignmentService.to_event(assignment)) if @assignment_filter.should_track(assignment)
    end

    def self.to_event(assignment)
      event = AmplitudeAnalytics::BaseEvent.new(
        '[Experiment] Assignment',
        user_id: assignment.user.user_id,
        device_id: assignment.user.device_id,
        event_properties: {},
        user_properties: {}
      )

      set = {}
      unset = {}

      assignment.results.sort.to_h.each do |flag_key, variant|
        next unless variant.key

        version = variant.metadata['flagVersion'] if variant.metadata
        segment_name = variant.metadata['segmentName'] if variant.metadata
        flag_type = variant.metadata['flagType'] if variant.metadata
        default = variant.metadata ? variant.metadata.fetch('default', false) : false
        event.event_properties["#{flag_key}.variant"] = variant.key
        event.event_properties["#{flag_key}.details"] = "v#{version} rule:#{segment_name}" if version && segment_name
        next if flag_type == FLAG_TYPE_MUTUAL_EXCLUSION_GROUP

        if default
          unset["[Experiment] #{flag_key}"] = '-'
        else
          set["[Experiment] #{flag_key}"] = variant.key
        end
      end
      event.user_properties['$set'] = set
      event.user_properties['$unset'] = unset
      event.insert_id = "#{event.user_id} #{event.device_id} #{AmplitudeExperiment.hash_code(assignment.canonicalize)} #{assignment.timestamp / DAY_MILLIS}"
      event
    end
  end
end
