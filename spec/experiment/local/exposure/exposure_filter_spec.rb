require 'spec_helper'
require 'experiment/local/exposure/exposure_filter'
require 'experiment/local/exposure/exposure'
require 'experiment/user'
require 'experiment/variant'

describe AmplitudeExperiment::ExposureFilter do
  let(:user) { AmplitudeExperiment::User.new(user_id: 'user', device_id: 'device') }

  describe '#should_track' do
    it 'returns true for single exposure' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      results = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      exposure = AmplitudeExperiment::Exposure.new(user, results)
      expect(filter.should_track(exposure)).to be true
    end

    it 'returns false for duplicate exposure' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      results = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      exposure1 = AmplitudeExperiment::Exposure.new(user, results)
      exposure2 = AmplitudeExperiment::Exposure.new(user, results)
      expect(filter.should_track(exposure1)).to be true
      expect(filter.should_track(exposure2)).to be false
    end

    it 'returns true for same user different results' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      results1 = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      results2 = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on')
      }
      exposure1 = AmplitudeExperiment::Exposure.new(user, results1)
      exposure2 = AmplitudeExperiment::Exposure.new(user, results2)
      expect(filter.should_track(exposure1)).to be true
      expect(filter.should_track(exposure2)).to be true
    end

    it 'returns true for same results different users' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      user1 = AmplitudeExperiment::User.new(user_id: 'user', device_id: 'device')
      user2 = AmplitudeExperiment::User.new(user_id: 'different user', device_id: 'device')
      results = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      exposure1 = AmplitudeExperiment::Exposure.new(user1, results)
      exposure2 = AmplitudeExperiment::Exposure.new(user2, results)
      expect(filter.should_track(exposure1)).to be true
      expect(filter.should_track(exposure2)).to be true
    end

    it 'returns false for empty results' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      user1 = AmplitudeExperiment::User.new(user_id: 'user', device_id: 'device')
      user2 = AmplitudeExperiment::User.new(user_id: 'different user', device_id: 'device')
      exposure1 = AmplitudeExperiment::Exposure.new(user1, {})
      exposure2 = AmplitudeExperiment::Exposure.new(user1, {})
      exposure3 = AmplitudeExperiment::Exposure.new(user2, {})
      expect(filter.should_track(exposure1)).to be false
      expect(filter.should_track(exposure2)).to be false
      expect(filter.should_track(exposure3)).to be false
    end

    it 'returns false for duplicate exposures with different ordering' do
      filter = AmplitudeExperiment::ExposureFilter.new(100)
      results1 = {
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on'),
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control')
      }
      results2 = {
        'flag-key-2' => AmplitudeExperiment::Variant.new(key: 'control', value: 'control'),
        'flag-key-1' => AmplitudeExperiment::Variant.new(key: 'on', value: 'on')
      }
      exposure1 = AmplitudeExperiment::Exposure.new(user, results1)
      exposure2 = AmplitudeExperiment::Exposure.new(user, results2)
      expect(filter.should_track(exposure1)).to be true
      expect(filter.should_track(exposure2)).to be false
    end
  end
end
