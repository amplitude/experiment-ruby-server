module Experiment
  # Variant
  class Variant
    attr_accessor :value, :payload

    # @param [String] value The value of the variant determined by the flag configuration
    # @param [Object] payload The attached payload, if any
    def initialize(value, payload = nil)
      @value = value
      @payload = payload
    end

    # @param [Variant] other
    def ==(other)
      value == other.value &&
        payload == other.payload
    end
  end
end
