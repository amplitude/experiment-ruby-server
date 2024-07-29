module AmplitudeExperiment
  DAY_MILLIS = 86_400_000
  # Assignment
  class Assignment
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
