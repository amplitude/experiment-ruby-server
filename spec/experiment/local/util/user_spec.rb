module AmplitudeExperiment
  RSpec.describe 'User to Evaluation Context' do
    it 'returns the correct context with user and groups' do
      user = User.new(
        device_id: 'device_id',
        user_id: 'user_id',
        country: 'country',
        city: 'city',
        language: 'language',
        platform: 'platform',
        version: 'version',
        user_properties: { k: 'v' },
        groups: { type: 'name' },
        group_properties: { type: { name: { gk: 'gv' } } }
      )
      context = AmplitudeExperiment.user_to_evaluation_context(user)
      expected_context = {
        user: {
          device_id: 'device_id',
          user_id: 'user_id',
          country: 'country',
          city: 'city',
          language: 'language',
          platform: 'platform',
          version: 'version',
          user_properties: { k: 'v' }
        },
        groups: {
          type: {
            group_name: 'name',
            group_properties: { gk: 'gv' }
          }
        }
      }
      expect(context).to eq(expected_context)
    end

    it 'returns the correct context with only user' do
      user = User.new(
        device_id: 'device_id',
        user_id: 'user_id',
        country: 'country',
        city: 'city',
        language: 'language',
        platform: 'platform',
        version: 'version',
        user_properties: { k: 'v' }
      )
      context = AmplitudeExperiment.user_to_evaluation_context(user)
      expected_context = {
        user: {
          device_id: 'device_id',
          user_id: 'user_id',
          country: 'country',
          city: 'city',
          language: 'language',
          platform: 'platform',
          version: 'version',
          user_properties: { k: 'v' }
        }
      }
      expect(context).to eq(expected_context)
    end

    it 'returns the correct context with only groups' do
      user = User.new(
        groups: { type: 'name' },
        group_properties: { type: { name: { gk: 'gv' } } }
      )
      context = AmplitudeExperiment.user_to_evaluation_context(user)
      expected_context = {
        groups: {
          type: {
            group_name: 'name',
            group_properties: { gk: 'gv' }
          }
        }
      }
      expect(context).to eq(expected_context)
    end

    it 'returns the correct context with only groups but no group properties' do
      user = User.new(
        groups: { type: 'name' }
      )
      context = AmplitudeExperiment.user_to_evaluation_context(user)
      expected_context = {
        groups: {
          type: {
            group_name: 'name'
          }
        }
      }
      expect(context).to eq(expected_context)
    end
  end
end
