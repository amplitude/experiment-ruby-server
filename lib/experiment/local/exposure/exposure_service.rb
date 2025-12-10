require_relative '../../../amplitude'
module AmplitudeExperiment
  # ExposureService
  class ExposureService
    def initialize(amplitude, exposure_filter)
      @amplitude = amplitude
      @exposure_filter = exposure_filter
    end

    def track(exposure)
      return unless @exposure_filter.should_track(exposure)

      events = ExposureService.to_exposure_events(exposure, @exposure_filter.ttl_millis)
      events.each do |event|
        @amplitude.track(event)
      end
    end

    def self.to_exposure_events(exposure, ttl_millis)
      events = []
      canonicalized = exposure.canonicalize
      exposure.results.each do |flag_key, variant|
        track_exposure = variant.metadata ? variant.metadata.fetch('trackExposure', true) : true
        next unless track_exposure

        # Skip default variant exposures
        is_default = variant.metadata ? variant.metadata.fetch('default', false) : false
        next if is_default

        # Determine user properties to set and unset.
        set_props = {}
        unset_props = {}
        flag_type = variant.metadata['flagType'] if variant.metadata
        if flag_type != 'mutual-exclusion-group'
          if variant.key
            set_props["[Experiment] #{flag_key}"] = variant.key
          elsif variant.value
            set_props["[Experiment] #{flag_key}"] = variant.value
          end
        end

        # Build event properties.
        event_properties = {}
        event_properties['[Experiment] Flag Key'] = flag_key
        if variant.key
          event_properties['[Experiment] Variant'] = variant.key
        elsif variant.value
          event_properties['[Experiment] Variant'] = variant.value
        end
        event_properties['metadata'] = variant.metadata if variant.metadata

        # Build event.
        event = AmplitudeAnalytics::BaseEvent.new(
          '[Experiment] Exposure',
          user_id: exposure.user.user_id,
          device_id: exposure.user.device_id,
          event_properties: event_properties,
          user_properties: {
            '$set' => set_props,
            '$unset' => unset_props
          },
          insert_id: "#{exposure.user.user_id} #{exposure.user.device_id} #{AmplitudeExperiment.hash_code("#{flag_key} #{canonicalized}")} #{exposure.timestamp / ttl_millis}"
        )
        event.groups = exposure.user.groups if exposure.user.groups

        events << event
      end
      events
    end
  end
end
