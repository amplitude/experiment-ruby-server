# frozen_string_literal: true

require 'json'

module AmplitudeExperiment
  module Evaluation
    class Distribution
      attr_accessor :variant, :range

      def self.from_hash(hash)
        new.tap do |dist|
          dist.variant = hash['variant']
          dist.range = hash['range']
        end
      end
    end

    class Allocation
      attr_accessor :range, :distributions

      def self.from_hash(hash)
        new.tap do |alloc|
          alloc.range = hash['range']
          alloc.distributions = hash['distributions']&.map { |d| Distribution.from_hash(d) }
        end
      end
    end

    class Condition
      attr_accessor :selector, :op, :values

      def self.from_hash(hash)
        new.tap do |cond|
          cond.selector = hash['selector']
          cond.op = hash['op']
          cond.values = hash['values']
        end
      end
    end

    class Bucket
      attr_accessor :selector, :salt, :allocations

      def self.from_hash(hash)
        new.tap do |bucket|
          bucket.selector = hash['selector']
          bucket.salt = hash['salt']
          bucket.allocations = hash['allocations']&.map { |a| Allocation.from_hash(a) }
        end
      end
    end

    class Segment
      attr_accessor :bucket, :conditions, :variant, :metadata

      def self.from_hash(hash)
        new.tap do |segment|
          segment.bucket = hash['bucket'] && Bucket.from_hash(hash['bucket'])
          segment.conditions = hash['conditions']&.map { |c| c.map { |inner| Condition.from_hash(inner) } }
          segment.variant = hash['variant']
          segment.metadata = hash['metadata']
        end
      end
    end

    class Variant
      attr_accessor :key, :value, :payload, :metadata

      def [](key)
        instance_variable_get("@#{key}")
      end

      def self.from_hash(hash)
        new.tap do |variant|
          variant.key = hash['key']
          variant.value = hash['value']
          variant.payload = hash['payload']
          variant.metadata = hash['metadata']
        end
      end
    end

    class Flag
      attr_accessor :key, :variants, :segments, :dependencies, :metadata

      def self.from_hash(hash)
        new.tap do |flag|
          flag.key = hash['key']
          flag.variants = hash['variants'].transform_values { |v| Variant.from_hash(v) }
          flag.segments = hash['segments'].map { |s| Segment.from_hash(s) }
          flag.dependencies = hash['dependencies']
          flag.metadata = hash['metadata']
        end
      end

      # Used for testing
      def ==(other)
        key == other.key
      end
    end

    module Operator
      IS = 'is'
      IS_NOT = 'is not'
      CONTAINS = 'contains'
      DOES_NOT_CONTAIN = 'does not contain'
      LESS_THAN = 'less'
      LESS_THAN_EQUALS = 'less or equal'
      GREATER_THAN = 'greater'
      GREATER_THAN_EQUALS = 'greater or equal'
      VERSION_LESS_THAN = 'version less'
      VERSION_LESS_THAN_EQUALS = 'version less or equal'
      VERSION_GREATER_THAN = 'version greater'
      VERSION_GREATER_THAN_EQUALS = 'version greater or equal'
      SET_IS = 'set is'
      SET_IS_NOT = 'set is not'
      SET_CONTAINS = 'set contains'
      SET_DOES_NOT_CONTAIN = 'set does not contain'
      SET_CONTAINS_ANY = 'set contains any'
      SET_DOES_NOT_CONTAIN_ANY = 'set does not contain any'
      REGEX_MATCH = 'regex match'
      REGEX_DOES_NOT_MATCH = 'regex does not match'
    end
  end
end
