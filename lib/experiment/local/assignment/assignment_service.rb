module AmplitudeExperiment
  # AssignmentService
  class AssignmentService
    def initialize(api_key, assignment_filter)
      @api_key = api_key
      @assignment_filter = assignment_filter
    end

    def to_event(assignment)
      event = Event.new(
        event_type: '[Experiment] Assignment',
        user_id: assignment.user.user_id,
        device_id: assignment.user.device_id,
        event_properties: {},
        user_properties: {}
      )

      assignment.results.each do |results_key, result|
        event.event_properties["#{results_key}.variant"] = result[:value]
      end

      set = {}
      unset = {}

      assignment.results.each do |results_key, result|
        next if result[:type] == FLAG_TYPE_MUTUAL_EXCLUSION_GROUP

        if result[:is_default_variant]
          unset["[Experiment] #{results_key}"] = '-'
        else
          set["[Experiment] #{results_key}"] = result[:value]
        end
      end

      event.user_properties['$set'] = set
      event.user_properties['$unset'] = unset

      event.insert_id = "#{event.user_id} #{event.device_id} #{assignment.canonicalize.hash} #{assignment.timestamp / DAY_MILLIS}"

      event
    end

  end
end
