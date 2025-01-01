# frozen_string_literal: true

module Evaluation
  # Engine for evaluating feature flags based on context
  class Engine
    def evaluate(context, flags)
      results = {}
      target = {
        'context' => context,
        'result' => results
      }

      flags.each do |flag|
        variant = evaluate_flag(target, flag)
        results[flag.key] = variant if variant
      end

      results
    end

    private

    def evaluate_flag(target, flag)
      result = nil
      flag.segments.each do |segment|
        result = evaluate_segment(target, flag, segment)
        if result
          # Merge all metadata into the result
          metadata = {}
          metadata.merge!(flag.metadata) if flag.metadata
          metadata.merge!(segment.metadata) if segment.metadata
          metadata.merge!(result.metadata) if result.metadata
          result.metadata = metadata
          break
        end
      end
      result
    end

    def evaluate_segment(target, flag, segment)
      if !segment.conditions
        # Null conditions always match
        variant_key = bucket(target, segment)
        variant_key ? flag.variants[variant_key] : nil
      else
        match = evaluate_conditions(target, segment.conditions)
        if match
          variant_key = bucket(target, segment)
          variant_key ? flag.variants[variant_key] : nil
        end
      end
    end

    def evaluate_conditions(target, conditions)
      # Outer list logic is "or" (||)
      conditions.any? do |inner_conditions|
        match = true
        inner_conditions.each do |condition|
          match = match_condition(target, condition)
          break unless match
        end
        match
      end
    end

    def match_condition(target, condition)
      prop_value = Evaluation.select(target, condition.selector)
      # Special matching for null properties and set type prop values and operators
      if !prop_value
        match_null(condition.op, condition.values)
      elsif set_operator?(condition.op)
        prop_value_string_list = coerce_string_array(prop_value)
        return false unless prop_value_string_list
        match_set(prop_value_string_list, condition.op, condition.values)
      else
        prop_value_string = coerce_string(prop_value)
        if prop_value_string
          match_string(prop_value_string, condition.op, condition.values)
        else
          false
        end
      end
    end

    def get_hash(key)
      Murmur3.hash32x86(key)
    end

    def bucket(target, segment)
      if !segment.bucket
        # Null bucket means segment is fully rolled out
        return segment.variant
      end

      bucketing_value = coerce_string(Evaluation.select(target, segment.bucket.selector))
      if !bucketing_value || bucketing_value.empty?
        # Null or empty bucketing value cannot be bucketed
        return segment.variant
      end

      key_to_hash = "#{segment.bucket.salt}/#{bucketing_value}"
      hash = get_hash(key_to_hash)
      allocation_value = hash % 100
      distribution_value = (hash / 100).floor

      segment.bucket.allocations.each do |allocation|
        allocation_start = allocation.range[0]
        allocation_end = allocation.range[1]
        if allocation_value >= allocation_start && allocation_value < allocation_end
          allocation.distributions.each do |distribution|
            distribution_start = distribution.range[0]
            distribution_end = distribution.range[1]
            if distribution_value >= distribution_start && distribution_value < distribution_end
              return distribution.variant
            end
          end
        end
      end

      segment.variant
    end

    def match_null(op, filter_values)
      contains_none = contains_none?(filter_values)
      case op
      when Operator::IS, Operator::CONTAINS, Operator::LESS_THAN,
        Operator::LESS_THAN_EQUALS, Operator::GREATER_THAN,
        Operator::GREATER_THAN_EQUALS, Operator::VERSION_LESS_THAN,
        Operator::VERSION_LESS_THAN_EQUALS, Operator::VERSION_GREATER_THAN,
        Operator::VERSION_GREATER_THAN_EQUALS, Operator::SET_IS,
        Operator::SET_CONTAINS, Operator::SET_CONTAINS_ANY
        contains_none
      when Operator::IS_NOT, Operator::DOES_NOT_CONTAIN,
        Operator::SET_DOES_NOT_CONTAIN, Operator::SET_DOES_NOT_CONTAIN_ANY
        !contains_none
      else
        false
      end
    end

    def match_set(prop_values, op, filter_values)
      case op
      when Operator::SET_IS
        set_equals?(prop_values, filter_values)
      when Operator::SET_IS_NOT
        !set_equals?(prop_values, filter_values)
      when Operator::SET_CONTAINS
        matches_set_contains_all?(prop_values, filter_values)
      when Operator::SET_DOES_NOT_CONTAIN
        !matches_set_contains_all?(prop_values, filter_values)
      when Operator::SET_CONTAINS_ANY
        matches_set_contains_any?(prop_values, filter_values)
      when Operator::SET_DOES_NOT_CONTAIN_ANY
        !matches_set_contains_any?(prop_values, filter_values)
      else
        false
      end
    end

    def match_string(prop_value, op, filter_values)
      case op
      when Operator::IS
        matches_is?(prop_value, filter_values)
      when Operator::IS_NOT
        !matches_is?(prop_value, filter_values)
      when Operator::CONTAINS
        matches_contains?(prop_value, filter_values)
      when Operator::DOES_NOT_CONTAIN
        !matches_contains?(prop_value, filter_values)
      when Operator::LESS_THAN, Operator::LESS_THAN_EQUALS,
        Operator::GREATER_THAN, Operator::GREATER_THAN_EQUALS
        matches_comparable?(prop_value, op, filter_values,
                            method(:parse_number),
                            method(:comparator))
      when Operator::VERSION_LESS_THAN, Operator::VERSION_LESS_THAN_EQUALS,
        Operator::VERSION_GREATER_THAN, Operator::VERSION_GREATER_THAN_EQUALS
        matches_comparable?(prop_value, op, filter_values,
                            SemanticVersion.method(:parse),
                            method(:comparator))
      when Operator::REGEX_MATCH
        matches_regex?(prop_value, filter_values)
      when Operator::REGEX_DOES_NOT_MATCH
        !matches_regex?(prop_value, filter_values)
      else
        false
      end
    end

    def matches_is?(prop_value, filter_values)
      if contains_booleans?(filter_values)
        lower = prop_value.downcase
        return filter_values.any? { |value| value.downcase == lower } if ['true', 'false'].include?(lower)
      end
      filter_values.any? { |value| prop_value == value }
    end

    def matches_contains?(prop_value, filter_values)
      filter_values.any? do |filter_value|
        prop_value.downcase.include?(filter_value.downcase)
      end
    end

    def matches_comparable?(prop_value, op, filter_values, type_transformer, type_comparator)
      prop_value_transformed = type_transformer.call(prop_value)
      filter_values_transformed = filter_values
                                    .map { |filter_value| type_transformer.call(filter_value) }
                                    .compact

      if !prop_value_transformed || filter_values_transformed.empty?
        filter_values.any? { |filter_value| comparator(prop_value, op, filter_value) }
      else
        filter_values_transformed.any? do |filter_value_transformed|
          type_comparator.call(prop_value_transformed, op, filter_value_transformed)
        end
      end
    end

    def comparator(prop_value, op, filter_value)
      case op
      when Operator::LESS_THAN, Operator::VERSION_LESS_THAN
        prop_value < filter_value
      when Operator::LESS_THAN_EQUALS, Operator::VERSION_LESS_THAN_EQUALS
        prop_value <= filter_value
      when Operator::GREATER_THAN, Operator::VERSION_GREATER_THAN
        prop_value > filter_value
      when Operator::GREATER_THAN_EQUALS, Operator::VERSION_GREATER_THAN_EQUALS
        prop_value >= filter_value
      else
        false
      end
    end

    def matches_regex?(prop_value, filter_values)
      filter_values.any? { |filter_value| !!(Regexp.new(filter_value) =~ prop_value) }
    end

    def contains_none?(filter_values)
      filter_values.any? { |filter_value| filter_value == '(none)' }
    end

    def contains_booleans?(filter_values)
      filter_values.any? do |filter_value|
        case filter_value.downcase
        when 'true', 'false'
          true
        else
          false
        end
      end
    end

    def parse_number(value)
      Float(value)
    rescue StandardError
      nil
    end

    def coerce_string(value)
      return nil if value.nil?
      return value.to_json if value.is_a?(Hash)
      value.to_s
    end

    def coerce_string_array(value)
      if value.is_a?(Array)
        value.map { |e| coerce_string(e) }.compact
      else
        string_value = value.to_s
        begin
          parsed_value = JSON.parse(string_value)
          if parsed_value.is_a?(Array)
            parsed_value.map { |e| coerce_string(e) }.compact
          else
            s = coerce_string(string_value)
            s ? [s] : nil
          end
        rescue JSON::ParserError
          s = coerce_string(string_value)
          s ? [s] : nil
        end
      end
    end

    def set_operator?(op)
      case op
      when Operator::SET_IS, Operator::SET_IS_NOT,
        Operator::SET_CONTAINS, Operator::SET_DOES_NOT_CONTAIN,
        Operator::SET_CONTAINS_ANY, Operator::SET_DOES_NOT_CONTAIN_ANY
        true
      else
        false
      end
    end

    def set_equals?(xa, ya)
      xs = Set.new(xa)
      ys = Set.new(ya)
      xs.size == ys.size && ys.all? { |y| xs.include?(y) }
    end

    def matches_set_contains_all?(prop_values, filter_values)
      return false if prop_values.length < filter_values.length
      filter_values.all? { |filter_value| matches_is?(filter_value, prop_values) }
    end

    def matches_set_contains_any?(prop_values, filter_values)
      filter_values.any? { |filter_value| matches_is?(filter_value, prop_values) }
    end
  end
end
