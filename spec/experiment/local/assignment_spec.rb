module AmplitudeExperiment
  describe AssignmentService do
    it 'assignment to event as expected' do
      filter = AssignmentFilter.new(100)
      service = AssignmentService.new('', filter)
      user = User.new(user_id: 'user', device_id: 'device')
      results = {}
      results['flag-key-1'] = {
        value: 'on',
        description: 'description-1',
        is_default_variant: false
      }
      results['flag-key-2'] = {
        value: 'control',
        description: 'description-2',
        is_default_variant: true
      }
      assignment = Assignment.new(user, results)

      event = service.to_event(assignment)

      expect(event.user_id).to eq(user.user_id)
      expect(event.device_id).to eq(user.device_id)
      expect(event.event_type).to eq('[Experiment] Assignment')

      event_properties = event.event_properties
      expect(event_properties.keys.length).to eq(2)
      expect(event_properties['flag-key-1.variant']).to eq('on')
      expect(event_properties['flag-key-2.variant']).to eq('control')

      user_properties = event.user_properties
      expect(user_properties.keys.length).to eq(2)
      expect(user_properties['$set'].keys.length).to eq(1)
      expect(user_properties['$unset'].keys.length).to eq(1)

      canonicalization = 'user device flag-key-1 on flag-key-2 control '
      expected = "user device #{canonicalization.hash} #{assignment.timestamp / DAY_MILLIS}"
      expect(assignment.canonicalize).to eq(canonicalization)
      expect(event.insert_id).to eq(expected)
    end

    describe AssignmentFilter do
      it 'filter - single assignment' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user', device_id: 'device')
        results = {
          'flag-key-1' => {
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
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
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
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
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
          }
        }
        results2 = {
          'flag-key-1' => {
            value: 'control',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'on',
            description: 'description-2',
            is_default_variant: true
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
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
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

        expect(filter.should_track(assignment1)).to eq(true)
        expect(filter.should_track(assignment2)).to eq(false)
        expect(filter.should_track(assignment3)).to eq(true)
      end

      it 'filter - duplicate assignments with different result ordering' do
        filter = AssignmentFilter.new(100)
        user = User.new(user_id: 'user')
        results1 = {
          'flag-key-1' => {
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
          }
        }
        results2 = {
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
          },
          'flag-key-1' => {
            value: 'on',
            description: 'description-1',
            is_default_variant: false
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
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
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
            value: 'on',
            description: 'description-1',
            is_default_variant: false
          },
          'flag-key-2' => {
            value: 'control',
            description: 'description-2',
            is_default_variant: true
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
