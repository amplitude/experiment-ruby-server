require 'spec_helper'
require 'experiment/local/exposure/exposure_service'
require 'experiment/local/exposure/exposure'
require 'experiment/user'
require 'experiment/variant'

describe AmplitudeExperiment::ExposureService do
  let(:user) { AmplitudeExperiment::User.new(user_id: 'user', device_id: 'device') }
  let(:mock_amplitude) { double('Amplitude') }
  let(:filter) { double('ExposureFilter', should_track: true, ttl_millis: AmplitudeExperiment::DAY_MILLIS) }
  let(:service) { AmplitudeExperiment::ExposureService.new(mock_amplitude, filter) }

  describe '#track' do
    it 'calls amplitude track for each event' do
      results = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      exposure = AmplitudeExperiment::Exposure.new(user, results)
      expect(mock_amplitude).to receive(:track).at_least(:once)
      service.track(exposure)
    end

    it 'does not track if filter returns false' do
      filter = double('ExposureFilter', should_track: false, ttl_millis: AmplitudeExperiment::DAY_MILLIS)
      service = AmplitudeExperiment::ExposureService.new(mock_amplitude, filter)
      results = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on')
      }
      exposure = AmplitudeExperiment::Exposure.new(user, results)
      expect(mock_amplitude).not_to receive(:track)
      service.track(exposure)
    end
  end

  describe '.to_exposure_events' do
    it 'creates one event per flag with comprehensive variants' do
      basic = AmplitudeExperiment::Variant.new(
        key: 'control',
        value: 'control',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => false
        }
      )
      different_value = AmplitudeExperiment::Variant.new(
        key: 'on',
        value: 'control',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => false
        }
      )
      default = AmplitudeExperiment::Variant.new(
        key: 'off',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => true
        }
      )
      mutex = AmplitudeExperiment::Variant.new(
        key: 'slot-1',
        value: 'slot-1',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'mutual-exclusion-group',
          'flagVersion' => 10,
          'default' => false
        }
      )
      holdout = AmplitudeExperiment::Variant.new(
        key: 'holdout',
        value: 'holdout',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'holdout-group',
          'flagVersion' => 10,
          'default' => false
        }
      )
      partial_metadata = AmplitudeExperiment::Variant.new(
        key: 'on',
        value: 'on',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'release'
        }
      )
      empty_metadata = AmplitudeExperiment::Variant.new(
        key: 'on',
        value: 'on'
      )
      empty_variant = AmplitudeExperiment::Variant.new
      results = {
        'basic' => basic,
        'different_value' => different_value,
        'default' => default,
        'mutex' => mutex,
        'holdout' => holdout,
        'partial_metadata' => partial_metadata,
        'empty_metadata' => empty_metadata,
        'empty_variant' => empty_variant
      }
      exposure = AmplitudeExperiment::Exposure.new(user, results)
      events = AmplitudeExperiment::ExposureService.to_exposure_events(exposure, AmplitudeExperiment::DAY_MILLIS)
      # Should exclude default (default=true) only
      # basic, different_value, mutex, holdout, partial_metadata, empty_metadata, empty_variant = 7 events
      expect(events.length).to eq(7)

      events.each do |event|
        expect(event.event_type).to eq('[Experiment] Exposure')
        expect(event.user_id).to eq(user.user_id)
        expect(event.device_id).to eq(user.device_id)

        flag_key = event.event_properties['[Experiment] Flag Key']
        expect(results[flag_key]).to be_truthy
        variant = results[flag_key]

        # Validate event properties
        if variant.key
          expect(event.event_properties['[Experiment] Variant']).to eq(variant.key)
        elsif variant.value
          expect(event.event_properties['[Experiment] Variant']).to eq(variant.value)
        end
        expect(event.event_properties['metadata']).to eq(variant.metadata) if variant.metadata

        # Validate user properties
        flag_type = variant.metadata ? variant.metadata['flagType'] : nil
        if flag_type == 'mutual-exclusion-group'
          expect(event.user_properties['$set']).to eq({})
          expect(event.user_properties['$unset']).to eq({})
        elsif variant.metadata && variant.metadata['default']
          expect(event.user_properties['$set']).to eq({})
          expect(event.user_properties['$unset']).to have_key("[Experiment] #{flag_key}")
        else
          if variant.key
            expect(event.user_properties['$set']["[Experiment] #{flag_key}"]).to eq(variant.key)
          elsif variant.value
            expect(event.user_properties['$set']["[Experiment] #{flag_key}"]).to eq(variant.value)
          end
          expect(event.user_properties['$unset']).to eq({})
        end
      end
    end
  end
end
