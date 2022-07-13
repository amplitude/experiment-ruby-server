module AmplitudeExperiment
  # Variant
  class Variant
    # The value of the variant determined by the flag configuration.
    # @return [String] the value of variant value
    attr_accessor :value

    # The attached payload, if any.
    # @return [Object, nil] the value of variant payload
    attr_accessor :payload

    # @param [String] value The value of the variant determined by the flag configuration.
    # @param [Object, nil] payload The attached payload, if any.
    def initialize(value, payload = nil)
      @value = value
      @payload = payload
    end

    # Determine if current variant equal other variant
    # @param [Variant] other
    def ==(other)
      value == other.value &&
        payload == other.payload
    end
  end
end
