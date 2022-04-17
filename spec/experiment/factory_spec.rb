require_relative '../../lib/experiment/factory'
API_KEY = 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3'.freeze

describe Experiment do
  describe '#init' do
    it 'test hold a singleton instance' do
      client1 = Experiment.init(API_KEY)
      client2 = Experiment.init(API_KEY)
      expect(client1).to equal client2
    end
  end
end
