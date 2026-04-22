# frozen_string_literal: true

module AmplitudeExperiment
  describe Evaluation::Engine do
    let(:engine) { Evaluation::Engine.new }

    def flag_with_condition(op, values)
      Evaluation::Flag.from_hash(
        'key' => 'test-flag',
        'variants' => {
          'on' => { 'key' => 'on', 'value' => 'on' }
        },
        'segments' => [
          {
            'conditions' => [[
              {
                'selector' => %w[context user user_properties test_prop],
                'op' => op,
                'values' => values
              }
            ]],
            'variant' => 'on'
          }
        ]
      )
    end

    def context_with_prop(value)
      {
        'user' => {
          'user_properties' => { 'test_prop' => value }
        }
      }
    end

    def evaluate(prop_value, op, values)
      flag = flag_with_condition(op, values)
      context = context_with_prop(prop_value)
      engine.evaluate(context, [flag])['test-flag']
    end

    def assert_match(prop_value, op, values)
      result = evaluate(prop_value, op, values)
      expect(result).not_to be_nil
      expect(result.key).to eq('on')
    end

    def assert_no_match(prop_value, op, values)
      result = evaluate(prop_value, op, values)
      expect(result).to be_nil
    end

    describe 'non-set operator array matching' do
      it 'matches scalar string IS' do
        assert_match('hello', Evaluation::Operator::IS, ['hello'])
      end

      it 'matches scalar string CONTAINS' do
        assert_match('hello', Evaluation::Operator::CONTAINS, ['ell'])
      end

      it 'matches scalar string GREATER_THAN' do
        assert_match('2', Evaluation::Operator::GREATER_THAN, ['1'])
      end

      it 'does not match scalar string IS when value differs' do
        assert_no_match('world', Evaluation::Operator::IS, ['hello'])
      end

      it 'matches non-string scalar GREATER_THAN' do
        assert_match(42, Evaluation::Operator::GREATER_THAN, ['1'])
      end

      it 'matches non-string scalar IS (boolean)' do
        assert_match(true, Evaluation::Operator::IS, ['true'])
      end

      it 'matches JSON array string with set operator' do
        assert_match('["a","b"]', Evaluation::Operator::SET_CONTAINS, ['a'])
      end

      it 'matches JSON array string with non-set operator' do
        assert_match('["a","b"]', Evaluation::Operator::IS, ['a'])
      end

      it 'matches collection with set operator' do
        assert_match(%w[a b], Evaluation::Operator::SET_CONTAINS, ['a'])
      end

      it 'matches collection with non-set operator' do
        assert_match(%w[a b], Evaluation::Operator::IS, ['a'])
      end

      it 'falls through for malformed JSON array and matches as scalar' do
        assert_match('[broken', Evaluation::Operator::IS, ['[broken'])
      end

      it 'does not match empty JSON array for set operator' do
        assert_no_match('[]', Evaluation::Operator::SET_CONTAINS, ['a'])
      end

      it 'treats leading-whitespace string as scalar for non-set operator' do
        assert_match(' ["a"]', Evaluation::Operator::IS, [' ["a"]'])
      end

      it 'treats leading-whitespace string as scalar for set operator (no match)' do
        assert_no_match(' ["a"]', Evaluation::Operator::SET_CONTAINS, ['a'])
      end
    end
  end
end
