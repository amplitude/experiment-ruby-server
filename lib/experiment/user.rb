module AmplitudeExperiment
  # Defines a user context for evaluation.
  # `device_id` and `user_id` are used for identity resolution.
  # All other predefined fields and user properties are used for
  # rule based user targeting.
  class User
    # Device ID for associating with an identity in Amplitude
    # @return [String, nil] the value of device id
    attr_accessor :device_id

    # User ID for associating with an identity in Amplitude
    # @return [String, nil] the value of user id
    attr_accessor :user_id

    # Predefined field, must be manually provided
    # @return [String, nil] the value of country
    attr_accessor :country

    # Predefined field, must be manually provided
    # @return [String, nil] the value of city
    attr_accessor :city

    # Predefined field, must be manually provided
    # @return [String, nil] the value of region
    attr_accessor :region

    # Predefined field, must be manually provided
    # @return [String, nil] the value of dma
    attr_accessor :dma

    # Predefined field, must be manually provided
    # @return [String, nil] the value of ip address
    attr_accessor :ip_address

    # Predefined field, must be manually provided
    # @return [String, nil] the value of language
    attr_accessor :language

    # Predefined field, must be manually provided
    # @return [String, nil] the value of platform
    attr_accessor :platform

    # Predefined field, must be manually provided
    # @return [String, nil] the value of version
    attr_accessor :version

    # Predefined field, must be manually provided
    # @return [String, nil] the value of os
    attr_accessor :os

    # Predefined field, must be manually provided
    # @return [String, nil] the value of device manufacturer
    attr_accessor :device_manufacturer

    # Predefined field, must be manually provided
    # @return [String, nil] the value of device brand
    attr_accessor :device_brand

    # Predefined field, must be manually provided
    # @return [String, nil] the value of device model
    attr_accessor :device_model

    # Predefined field, must be manually provided
    # @return [String, nil] the value of carrier
    attr_accessor :carrier

    # Predefined field, auto populated, can be manually overridden
    # @return [String, nil] the value of library
    attr_accessor :library

    # Custom user properties
    # @return [Hash, nil] the value of user properties
    attr_accessor :user_properties

    # Predefined field, must be manually provided
    # @return [Hash, nil] the value of groups
    attr_accessor :groups

    # Predefined field, must be manually provided
    # @return [Hash, nil] the value of group properties
    attr_accessor :group_properties

    # Cohort IDs for the user
    # @return [Hash, nil] the value of cohort_ids
    attr_accessor :cohort_ids

    # Cohort IDs for the user's groups
    # @return [Hash, nil] the value of group_cohort_ids
    attr_accessor :group_cohort_ids

    # @param [String, nil] device_id Device ID for associating with an identity in Amplitude
    # @param [String, nil] user_id User ID for associating with an identity in Amplitude
    # @param [String, nil] country Predefined field, must be manually provided
    # @param [String, nil] city Predefined field, must be manually provided
    # @param [String, nil] region Predefined field, must be manually provided
    # @param [String, nil] dma Predefined field, must be manually provided
    # @param [String, nil] ip_address Predefined field, must be manually provided
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
    # @param [Hash, nil] groups List of groups the user belongs to
    # @param [Hash, nil] group_properties Custom properties for groups
    def initialize(device_id: nil, user_id: nil, country: nil, city: nil, region: nil, dma: nil, ip_address: nil, language: nil,
                   platform: nil, version: nil, os: nil, device_manufacturer: nil, device_brand: nil,
                   device_model: nil, carrier: nil, library: nil, user_properties: nil, groups: nil, group_properties: nil,
                   cohort_ids: nil, group_cohort_ids: nil)
      @device_id = device_id
      @user_id = user_id
      @country = country
      @city = city
      @region = region
      @dma = dma
      @ip_address = ip_address
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
      @groups = groups
      @group_properties = group_properties
      @cohort_ids = cohort_ids
      @group_cohort_ids = group_cohort_ids
    end

    # Return User as Hash.
    # @return [Hash] Hash object with user values
    def as_json(_options = {})
      {
        'device_id' => @device_id,
        'user_id' => @user_id,
        'country' => @country,
        'city' => @city,
        'region' => @region,
        'dma' => @dma,
        'ip_address' => @ip_address,
        'language' => @language,
        'platform' => @platform,
        'version' => @version,
        'os' => @os,
        'device_manufacturer' => @device_manufacturer,
        'device_brand' => @device_brand,
        'device_model' => @device_model,
        'carrier' => @carrier,
        'library' => @library,
        'user_properties' => @user_properties,
        'groups' => @groups,
        'group_properties' => @group_properties,
        'cohort_ids' => @cohort_ids,
        'group_cohort_ids' => @group_cohort_ids
      }.compact
    end

    # Return user information as JSON string.
    # @return [String] details about user as json string
    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    def add_group_cohort_ids(group_type, group_name, cohort_ids)
      @group_cohort_ids ||= {}

      group_names = @group_cohort_ids[group_type] ||= {}
      group_names[group_name] = cohort_ids
    end
  end
end
