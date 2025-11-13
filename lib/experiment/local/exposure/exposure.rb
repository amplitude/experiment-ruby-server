module AmplitudeExperiment
  # Exposure is a class that represents a user's exposure to a set of flags.
  class Exposure
    attr_accessor :user, :results, :timestamp

    def initialize(user, results)
      @user = user
      @results = results
      @timestamp = (Time.now.to_f * 1000).to_i
    end

    def canonicalize
      sb = "#{@user&.user_id&.strip} #{@user&.device_id&.strip} "
      results.sort.to_h.each do |key, value|
        next unless value.key

        sb += "#{key.strip} #{value.key&.strip} "
      end
      sb
    end
  end
end
