# frozen_string_literal: true

RSpec.describe Evaluation do
  let(:primitive_object) do
    {
      'null' => nil,
      'string' => 'value',
      'number' => 13,
      'boolean' => true
    }
  end

  let(:nested_object) do
    primitive_object.merge('object' => primitive_object)
  end

  context '.select' do
    it 'handles non-existent paths' do
      expect(described_class.select(nested_object, %w[does not exist])).to be_nil
    end

    it 'handles nil values' do
      expect(described_class.select(nested_object, ['null'])).to be_nil
    end

    it 'selects primitive values' do
      expect(described_class.select(nested_object, ['string'])).to eq('value')
      expect(described_class.select(nested_object, ['number'])).to eq(13)
      expect(described_class.select(nested_object, ['boolean'])).to eq(true)
    end

    it 'selects object values' do
      expect(described_class.select(nested_object, ['object'])).to eq(primitive_object)
    end

    it 'selects nested values' do
      expect(described_class.select(nested_object, %w[object string])).to eq('value')
      expect(described_class.select(nested_object, %w[object number])).to eq(13)
      expect(described_class.select(nested_object, %w[object boolean])).to eq(true)
    end

    it 'handles non-existent nested paths' do
      expect(described_class.select(nested_object, %w[object does not exist])).to be_nil
    end
  end
end
