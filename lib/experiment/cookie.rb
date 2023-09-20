require 'base64'
require 'json'

module AmplitudeExperiment
  # This class provides utility functions for parsing and handling identity from Amplitude cookies.
  class AmplitudeCookie
    # Get the cookie name that Amplitude sets for the provided
    #
    # @param [String] api_key The Amplitude API Key
    # @param [Boolean] new_format True if the cookie is in the Browser SDK 2.0 format
    # @return [String] The cookie name that Amplitude sets for the provided
    def self.cookie_name(api_key, new_format: false)
      raise ArgumentError, 'Invalid Amplitude API Key' if api_key.nil?

      if new_format
        raise ArgumentError, 'Invalid Amplitude API Key' if api_key.length < 10

        return "AMP_#{api_key[0..9]}"
      end
      raise ArgumentError, 'Invalid Amplitude API Key' if api_key.length < 6

      "amp_#{api_key[0..5]}"
    end

    # Parse a cookie string and returns user
    #
    # @param [String] amplitude_cookie A string from the amplitude cookie
    # @param [Boolean] new_format True if the cookie is in the Browser SDK 2.0 format
    # @return [User] a Experiment User context containing a device_id and user_id
    def self.parse(amplitude_cookie, new_format: false)
      if new_format
        begin
          decoding = Base64.decode64(amplitude_cookie).force_encoding('UTF-8')
          json_data = URI.decode_www_form_component(decoding)
          user_session_hash = JSON.parse(json_data)
          return User.new(user_id: user_session_hash['userId'], device_id: user_session_hash['deviceId'])
        rescue StandardError
          return User.new()
        end
      end
      values = amplitude_cookie.split('.', -1)
      user_id = nil
      unless values[1].nil? || values[1].empty?
        begin
          user_id = Base64.decode64(values[1]).force_encoding('UTF-8')
        rescue StandardError
          user_id = nil
        end
      end
      User.new(user_id: user_id, device_id: values[0])
    end

    # Generates a cookie string to set for the Amplitude Javascript SDK
    #
    # @param [String] device_id A device id to set
    # @param [Boolean] new_format True if the cookie is in the Browser SDK 2.0 format
    # @return [String] A cookie string to set for the Amplitude Javascript SDK to read
    def self.generate(device_id, new_format: false)
      return "#{device_id}.........." unless new_format

      user_session_hash = {
        'deviceId' => device_id
      }
      json_data = JSON.generate(user_session_hash)
      encoded_json = URI.encode_www_form_component(json_data)
      Base64.strict_encode64(encoded_json)
    end
  end
end
