require 'logger'
require 'time'

# Amplitude
module AmplitudeAnalytics
  def self.logger
    @logger ||= Logger.new($stdout, progname: LOGGER_NAME)
  end

  def self.current_milliseconds
    (Time.now.to_f * 1000).to_i
  end

  def self.truncate(obj)
    case obj
    when Hash
      if obj.length > MAX_PROPERTY_KEYS
        logger.error("Too many properties. #{MAX_PROPERTY_KEYS} maximum.")
        return {}
      end
      obj.each { |key, value| obj[key] = truncate(value) }
    when Array
      obj.map! { |element| truncate(element) }
    when String
      obj = obj[0, MAX_STRING_LENGTH]
    end
    obj
  end
end
