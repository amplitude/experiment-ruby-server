module AmplitudeExperiment
  # Variant
  class Variant
    # The key of the variant determined by the flag configuration.
    # @return [String] the value of variant key
    attr_accessor :key

    # The value of the variant determined by the flag configuration.
    # @return [String] the value of variant value
    attr_accessor :value

    # The attached payload, if any.
    # @return [Object, nil] the value of variant payload
    attr_accessor :payload

    attr_accessor :metadata

    # @param [String] value The value of the variant determined by the flag configuration.
    # @param [Object, nil] payload The attached payload, if any.
    def initialize(value, payload = nil, key = nil, metadata = nil)
      @key = key
      @value = value
      @payload = payload
      @metadata = metadata
    end

    # Determine if current variant equal other variant
    # @param [Variant] other
    def ==(other)
      key == other.key && value == other.value &&
        payload == other.payload
    end
  end
end
