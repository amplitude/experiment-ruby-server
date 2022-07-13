require 'base64'

module AmplitudeExperiment
  # This class provides utility functions for parsing and handling identity from Amplitude cookies.
  class AmplitudeCookie
    # Get the cookie name that Amplitude sets for the provided
    #
    # @param [String] api_key The Amplitude API Key
    # @return [String] The cookie name that Amplitude sets for the provided
    def self.cookie_name(api_key)
      raise ArgumentError, 'Invalid Amplitude API Key' if api_key.nil? || api_key.length < 6

      "amp_#{api_key[0..5]}"
    end

    # Parse a cookie string and returns user
    #
    # @param [String] amplitude_cookie A string from the amplitude cookie
    # @return [User] a Experiment User context containing a device_id and user_id
    def self.parse(amplitude_cookie)
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
    # @return [String] A cookie string to set for the Amplitude Javascript SDK to read
    def self.generate(device_id)
      "#{device_id}.........."
    end
  end
end
