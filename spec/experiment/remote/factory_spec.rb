require 'spec_helper'
API_KEY = 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3'.freeze

describe AmplitudeExperiment do
  describe '#init' do
    it 'test hold a singleton instance' do
      client1 = AmplitudeExperiment.init(API_KEY)
      client2 = AmplitudeExperiment.init(API_KEY)
      expect(client1).to equal client2
    end
  end
end
