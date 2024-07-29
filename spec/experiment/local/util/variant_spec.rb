module AmplitudeExperiment
  # RSpec tests
  RSpec.describe 'EvaluationVariant' do
    describe '#AmplitudeExperiment.evaluation_variant_json_to_variant' do
      it 'handles string value' do
        evaluation_variant = { 'key' => 'on', 'value' => 'test' }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: 'test'))
      end

      it 'handles boolean value' do
        evaluation_variant = { 'key' => 'on', 'value' => true }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: 'true'))
      end

      it 'handles int value' do
        evaluation_variant = { 'key' => 'on', 'value' => 10 }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: '10'))
      end

      it 'handles float value' do
        evaluation_variant = { 'key' => 'on', 'value' => 10.2 }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: '10.2'))
      end

      it 'handles array value' do
        evaluation_variant = { 'key' => 'on', 'value' => [1, 2, 3] }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: '[1,2,3]'))
      end

      it 'handles object value' do
        evaluation_variant = { 'key' => 'on', 'value' => { 'k' => 'v' } }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: '{"k":"v"}'))
      end

      it 'handles null value' do
        evaluation_variant = { 'key' => 'on', 'value' => nil }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: nil))
      end

      it 'handles undefined value' do
        evaluation_variant = { 'key' => 'on' }
        variant = AmplitudeExperiment.evaluation_variant_json_to_variant(evaluation_variant)
        expect(variant).to eq(Variant.new(key: 'on', value: nil))
      end
    end

    describe '#AmplitudeExperiment.evaluation_variants_json_to_variants' do
      it 'handles multiple variants' do
        evaluation_variants = {
          'string' => { 'key' => 'on', 'value' => 'test' },
          'boolean' => { 'key' => 'on', 'value' => true },
          'int' => { 'key' => 'on', 'value' => 10 },
          'float' => { 'key' => 'on', 'value' => 10.2 },
          'array' => { 'key' => 'on', 'value' => [1, 2, 3] },
          'object' => { 'key' => 'on', 'value' => { 'k' => 'v' } },
          'null' => { 'key' => 'on', 'value' => nil },
          'undefined' => { 'key' => 'on' }
        }
        variants = AmplitudeExperiment.evaluation_variants_json_to_variants(evaluation_variants)
        expected_variants = {
          'string' => Variant.new(key: 'on', value: 'test'),
          'boolean' => Variant.new(key: 'on', value: 'true'),
          'int' => Variant.new(key: 'on', value: '10'),
          'float' => Variant.new(key: 'on', value: '10.2'),
          'array' => Variant.new(key: 'on', value: '[1,2,3]'),
          'object' => Variant.new(key: 'on', value: '{"k":"v"}'),
          'null' => Variant.new(key: 'on', value: nil),
          'undefined' => Variant.new(key: 'on', value: nil)
        }
        expect(variants).to eq(expected_variants)
      end
    end
  end
end
