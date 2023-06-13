require 'spec_helper'
API_KEY = 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3'.freeze

describe AmplitudeExperiment do
  describe '#init' do
    it 'test hold a singleton instance for local evaluation client' do
      client1 = AmplitudeExperiment.initialize_local(API_KEY)
      client2 = AmplitudeExperiment.initialize_local(API_KEY)
      expect(client1).to equal client2
    end
    it 'test hold a different instance for different api keys' do
      client1 = AmplitudeExperiment.initialize_local(API_KEY)
      client2 = AmplitudeExperiment.initialize_local('different-api-key')
      expect(client1).not_to equal client2
    end
  end
end
