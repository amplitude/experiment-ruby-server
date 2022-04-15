module Experiment
  # Defines a user context for evaluation.
  # `device_id` and `user_id` are used for identity resolution.
  # All other predefined fields and user properties are used for
  # rule based user targeting.
  class User
    attr_accessor :device_id, :user_id, :country, :city, :region, :dma, :language, :platform, :version, :os,
                  :device_manufacturer, :device_brand, :device_model, :carrier, :library, :user_properties

    # @param [String, nil] device_id Device ID for associating with an identity in Amplitude
    # @param [String, nil] user_id User ID for associating with an identity in Amplitude
    # @param [String, nil] country Predefined field, must be manually provided
    # @param [String, nil] city Predefined field, must be manually provided
    # @param [String, nil] region Predefined field, must be manually provided
    # @param [String, nil] dma Predefined field, must be manually provided
    # @param [String, nil] language Predefined field, must be manually provided
    # @param [String, nil] platform Predefined field, must be manually provided
    # @param [String, nil] version Predefined field, must be manually provided
    # @param [String, nil] os Predefined field, must be manually provided
    # @param [String, nil] device_manufacturer Predefined field, must be manually provided
    # @param [String, nil] device_brand Predefined field, must be manually provided
    # @param [String, nil] device_model Predefined field, must be manually provided
    # @param [String, nil] carrier Predefined field, must be manually provided
    # @param [String, nil] library Predefined field, auto populated, can be manually overridden
    # @param [Hash, nil] user_properties Custom user properties
    def initialize(device_id: nil, user_id: nil, country: nil, city: nil, region: nil, dma: nil, language: nil,
                   platform: nil, version: nil, os: nil, device_manufacturer: nil, device_brand: nil,
                   device_model: nil, carrier: nil, library: nil, user_properties: nil)
      @device_id = device_id
      @user_id = user_id
      @country = country
      @city = city
      @region = region
      @dma = dma
      @language = language
      @platform = platform
      @version = version
      @os = os
      @device_manufacturer = device_manufacturer
      @device_brand = device_brand
      @device_model = device_model
      @carrier = carrier
      @library = library
      @user_properties = user_properties
    end

    def as_json(_options = {})
      {
        device_id: @device_id,
        user_id: @user_id,
        country: @country,
        city: @city,
        region: @region,
        dma: @dma,
        language: @language,
        platform: @platform,
        version: @version,
        os: @os,
        device_manufacturer: @device_manufacturer,
        device_brand: @device_brand,
        device_model: @device_model,
        carrier: @carrier,
        library: @library,
        user_properties: @user_properties
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end
  end
end
