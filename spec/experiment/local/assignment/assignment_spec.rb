module AmplitudeExperiment
  describe AssignmentService do
    let(:instance) { double('Amplitude') }
    let(:user) { User.new(user_id: 'user', device_id: 'device') }

    def build_variant(key, value, metadata = {})
      Variant.new(
        key: key,
        value: value,
        metadata: metadata
      )
    end

    it 'assignment to event as expected' do
      variants = {
        'basic' => build_variant('control', 'control', 'segmentName' => 'All Other Users', 'flagType' => 'experiment', 'flagVersion' => 10, 'default' => false),
        'different_value' => build_variant('on', 'control', 'segmentName' => 'All Other Users', 'flagType' => 'experiment', 'flagVersion' => 10, 'default' => false),
        'default' => build_variant('off', nil, 'segmentName' => 'All Other Users', 'flagType' => 'experiment', 'flagVersion' => 10, 'default' => true),
        'mutex' => build_variant('slot-1', 'slot-1', 'segmentName' => 'All Other Users', 'flagType' => 'mutual-exclusion-group', 'flagVersion' => 10, 'default' => false),
        'holdout' => build_variant('holdout', 'holdout', 'segmentName' => 'All Other Users', 'flagType' => 'holdout-group', 'flagVersion' => 10, 'default' => false),
        'partial_metadata' => build_variant('on', 'on', 'segmentName' => 'All Other Users', 'flagType' => 'release'),
        'empty_metadata' => build_variant('on', 'on'),
        'empty_variant' => build_variant(nil, nil)
      }
      assignment = Assignment.new(user, variants)
      event = AssignmentService.to_event(assignment)

      expect(event.user_id).to eq(user.user_id)
      expect(event.device_id).to eq(user.device_id)
      expect(event.event_type).to eq('[Experiment] Assignment')

      event_properties = event.event_properties
      expect(event_properties['basic.variant']).to eq('control')
      expect(event_properties['basic.details']).to eq('v10 rule:All Other Users')
      expect(event_properties['different_value.variant']).to eq('on')
      expect(event_properties['different_value.details']).to eq('v10 rule:All Other Users')
      expect(event_properties['default.variant']).to eq('off')
      expect(event_properties['default.details']).to eq('v10 rule:All Other Users')
      expect(event_properties['mutex.variant']).to eq('slot-1')
      expect(event_properties['mutex.details']).to eq('v10 rule:All Other Users')
      expect(event_properties['holdout.variant']).to eq('holdout')
      expect(event_properties['holdout.details']).to eq('v10 rule:All Other Users')
      expect(event_properties['partial_metadata.variant']).to eq('on')
      expect(event_properties['empty_metadata.variant']).to eq('on')

      user_properties = event.user_properties
      set_properties = user_properties['$set']
      expect(set_properties['[Experiment] basic']).to eq('control')
      expect(set_properties['[Experiment] different_value']).to eq('on')
      expect(set_properties['[Experiment] holdout']).to eq('holdout')
      expect(set_properties['[Experiment] partial_metadata']).to eq('on')
      expect(set_properties['[Experiment] empty_metadata']).to eq('on')
      unset_properties = user_properties['$unset']
      expect(unset_properties['[Experiment] default']).to eq('-')

      canonicalization = 'user device basic control default off different_value on empty_metadata on holdout holdout mutex slot-1 partial_metadata on '
      expected = "user device #{AmplitudeExperiment.hash_code(canonicalization)} #{assignment.timestamp / DAY_MILLIS}"
      expect(event.insert_id).to eq(expected)
    end

    it 'calls track on the Amplitude instance' do
      service = AssignmentService.new(instance, AssignmentFilter.new(2))
      user = User.new(user_id: 'user', device_id: 'device')
      results = { 'flag-key-1' => Variant.new(key: 'on') }
      allow(instance).to receive(:track)
      service.track(Assignment.new(user, results))
      expect(instance).to have_received(:track)
    end
  end

  describe AssignmentFilter do
    let(:filter) { AssignmentFilter.new(100) }
    let(:user) { User.new(user_id: 'user', device_id: 'device') }
    let(:variant_on) { Variant.new(key: 'on', value: 'on') }
    let(:variant_control) { Variant.new(key: 'control', value: 'control') }
    let(:results) { { 'flag-key-1' => variant_on, 'flag-key-2' => variant_control } }

    it 'filters single assignment' do
      assignment = Assignment.new(user, results)
      expect(filter.should_track(assignment)).to eq(true)
    end

    it 'filters duplicate assignment' do
      assignment1 = Assignment.new(user, results)
      assignment2 = Assignment.new(user, results)
      filter.should_track(assignment1)
      expect(filter.should_track(assignment2)).to eq(false)
    end

    it 'filters same user different results' do
      results1 = results
      results2 = {
        'flag-key-1' => variant_control,
        'flag-key-2' => variant_on
      }
      assignment1 = Assignment.new(user, results1)
      assignment2 = Assignment.new(user, results2)
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(true)
    end

    it 'filters same result different user' do
      user1 = User.new(user_id: 'user1')
      user2 = User.new(user_id: 'different-user')
      assignment1 = Assignment.new(user1, results)
      assignment2 = Assignment.new(user2, results)
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(true)
    end

    it 'filters empty result' do
      user1 = User.new(user_id: 'user')
      user2 = User.new(user_id: 'different-user')
      assignment1 = Assignment.new(user1, {})
      assignment2 = Assignment.new(user1, {})
      assignment3 = Assignment.new(user2, {})
      expect(filter.should_track(assignment1)).to eq(false)
      expect(filter.should_track(assignment2)).to eq(false)
      expect(filter.should_track(assignment3)).to eq(false)
    end

    it 'filters duplicate assignments with different result ordering' do
      results1 = results
      results2 = {
        'flag-key-2' => variant_control,
        'flag-key-1' => variant_on
      }
      assignment1 = Assignment.new(user, results1)
      assignment2 = Assignment.new(user, results2)
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(false)
    end

    it 'handles LRU replacement' do
      filter = AssignmentFilter.new(2)
      user1 = User.new(user_id: 'user1')
      user2 = User.new(user_id: 'user2')
      user3 = User.new(user_id: 'user3')
      assignment1 = Assignment.new(user1, results)
      assignment2 = Assignment.new(user2, results)
      assignment3 = Assignment.new(user3, results)
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(true)
      expect(filter.should_track(assignment3)).to eq(true)
      expect(filter.should_track(assignment1)).to eq(true)
    end

    it 'handles LRU TTL-based expiration' do
      filter = AssignmentFilter.new(2, 1000)
      user1 = User.new(user_id: 'user1')
      user2 = User.new(user_id: 'user2')
      assignment1 = Assignment.new(user1, results)
      assignment2 = Assignment.new(user2, results)
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment1)).to eq(false)
      sleep 1.05
      expect(filter.should_track(assignment1)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(true)
      expect(filter.should_track(assignment2)).to eq(false)
      sleep 0.95
      expect(filter.should_track(assignment2)).to eq(false)
    end
  end
end
