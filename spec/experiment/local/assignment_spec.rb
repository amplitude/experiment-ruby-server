module AmplitudeExperiment
  describe AssignmentService do
    user = User.new(user_id: 'user', device_id: 'device')
    it 'assignment to event as expected' do
      basic = Variant.new(
        key: 'control',
        value: 'control',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => false
        }
      )
      different_value = Variant.new(
        key: 'on',
        value: 'control',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => false
        }
      )
      default = Variant.new(
        key: 'off',
        value: nil,
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'experiment',
          'flagVersion' => 10,
          'default' => true
        }
      )
      mutex = Variant.new(
        key: 'slot-1',
        value: 'slot-1',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'mutual-exclusion-group',
          'flagVersion' => 10,
          'default' => false
        }
      )
      holdout = Variant.new(
        key: 'holdout',
        value: 'holdout',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'holdout-group',
          'flagVersion' => 10,
          'default' => false
        }
      )
      partial_metadata = Variant.new(
        key: 'on',
        value: 'on',
        metadata: {
          'segmentName' => 'All Other Users',
          'flagType' => 'release'
        }
      )
      empty_metadata = Variant.new(
        key: 'on',
        value: 'on'
      )
      empty_variant = Variant.new
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
      assignment = Assignment.new(user, results)
      event = AssignmentService.to_event(assignment)
      puts event
      expect(event.user_id).to eq(user.user_id)
      expect(event.device_id).to eq(user.device_id)
      expect(event.event_type).to eq('[Experiment] Assignment')

      # Validate event properties
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

      # Validate user properties
      user_properties = event.user_properties
      set_properties = user_properties['$set']
      expect(set_properties['[Experiment] basic']).to eq('control')
      expect(set_properties['[Experiment] different_value']).to eq('on')
      expect(set_properties['[Experiment] holdout']).to eq('holdout')
      expect(set_properties['[Experiment] partial_metadata']).to eq('on')
      expect(set_properties['[Experiment] empty_metadata']).to eq('on')
      unset_properties = user_properties['$unset']
      expect(unset_properties['[Experiment] default']).to eq('-')

      # Validate insert id
      canonicalization = 'user device basic control default off different_value on empty_metadata on holdout holdout mutex slot-1 partial_metadata on '
      expected = "user device #{AmplitudeExperiment.hash_code(canonicalization)} #{assignment.timestamp / DAY_MILLIS}"
      expect(event.insert_id).to eq(expected)
    end

    describe AssignmentFilter do
      it 'filter - single assignment' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user', device_id: 'device')
        results = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        assignment = Assignment.new(user, results)

        expect(filter.should_track(assignment)).to eq(true)
      end

      it 'filter - duplicate assignment' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user', device_id: 'device')
        results = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        assignment1 = Assignment.new(user, results)
        assignment2 = Assignment.new(user, results)

        filter.should_track(assignment1)
        expect(filter.should_track(assignment2)).to eq(false)
      end

      it 'filter - same user different results' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user', device_id: 'device')
        results1 = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        results2 = {
          'flag-key-1' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        assignment1 = Assignment.new(user, results1)
        assignment2 = Assignment.new(user, results2)

        expect(filter.should_track(assignment1)).to eq(true)
        expect(filter.should_track(assignment2)).to eq(true)
      end

      it 'filter - same result different user' do
        filter = AssignmentFilter.new(100)
        user1 = User.new(user_id: 'user')
        user2 = User.new(user_id: 'different-user')
        results = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        assignment1 = Assignment.new(user1, results)
        assignment2 = Assignment.new(user2, results)

        expect(filter.should_track(assignment1)).to eq(true)
        expect(filter.should_track(assignment2)).to eq(true)
      end

      it 'filter - empty result' do
        filter = AssignmentFilter.new(100)
        user1 = User.new(user_id: 'user')
        user2 = User.new(user_id: 'different-user')

        assignment1 = Assignment.new(user1, {})
        assignment2 = Assignment.new(user1, {})
        assignment3 = Assignment.new(user2, {})

        expect(filter.should_track(assignment1)).to eq(false)
        expect(filter.should_track(assignment2)).to eq(false)
        expect(filter.should_track(assignment3)).to eq(false)
      end

      it 'filter - duplicate assignments with different result ordering' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user')
        results1 = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        results2 = {
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          },
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          }
        }

        assignment1 = Assignment.new(user, results1)
        assignment2 = Assignment.new(user, results2)

        expect(filter.should_track(assignment1)).to eq(true)
        expect(filter.should_track(assignment2)).to eq(false)
      end

      it 'filter - lru replacement' do
        filter = AssignmentFilter.new(2)
        user1 = User.new(user_id: 'user1')
        user2 = User.new(user_id: 'user2')
        user3 = User.new(user_id: 'user3')
        results = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
        assignment1 = Assignment.new(user1, results)
        assignment2 = Assignment.new(user2, results)
        assignment3 = Assignment.new(user3, results)

        expect(filter.should_track(assignment1)).to eq(true)
        expect(filter.should_track(assignment2)).to eq(true)
        expect(filter.should_track(assignment3)).to eq(true)
        expect(filter.should_track(assignment1)).to eq(true)
      end

      it 'filter - lru ttl-based expiration' do
        filter = AssignmentFilter.new(2, 1000)
        user1 = User.new(user_id: 'user1')
        user2 = User.new(user_id: 'user2')
        results = {
          'flag-key-1' => {
            'variant' => { 'key' => 'on' },
            'description' => 'description-1',
            'isDefaultVariant' => false
          },
          'flag-key-2' => {
            'variant' => { 'key' => 'control' },
            'description' => 'description-2',
            'isDefaultVariant' => true
          }
        }
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
end
