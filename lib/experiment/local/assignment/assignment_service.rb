require_relative '../../../amplitude'
module AmplitudeExperiment
  # AssignmentService
  class AssignmentService
    attr_reader :amplitude

    def initialize(amplitude, assignment_filter)
      @amplitude = amplitude
      @assignment_filter = assignment_filter
    end

    def track(assignment)
      @amplitude.track(to_event(assignment)) if @assignment_filter.should_track(assignment)
    end

    def to_event(assignment)
      event = AmplitudeAnalytics::BaseEvent.new(
        '[Experiment] Assignment',
        user_id: assignment.user.user_id,
        device_id: assignment.user.device_id,
        event_properties: {},
        user_properties: {}
      )

      assignment.results.each do |results_key, result|
        event.event_properties["#{results_key}.variant"] = result['variant']['key']
      end

      set = {}
      unset = {}

      assignment.results.each do |results_key, result|
        next if result['type'] == FLAG_TYPE_MUTUAL_EXCLUSION_GROUP

        if result['isDefaultVariant']
          unset["[Experiment] #{results_key}"] = '-'
        else
          set["[Experiment] #{results_key}"] = result['variant']['key']
        end
      end

      event.user_properties['$set'] = set
      event.user_properties['$unset'] = unset

      event.insert_id = "#{event.user_id} #{event.device_id} #{AmplitudeExperiment.hash_code(assignment.canonicalize)} #{assignment.timestamp / DAY_MILLIS}"

      event
    end
  end
end
