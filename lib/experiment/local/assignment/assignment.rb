module AmplitudeExperiment
  FLAG_TYPE_MUTUAL_EXCLUSION_GROUP = 'mutual_exclusion_group'.freeze
  DAY_MILLIS = 86_400_000
  # Assignment
  class Assignment
    attr_accessor :user, :results, :timestamp

    def initialize(user, results)
      @user = user
      @results = results
      @timestamp = Time.now.strftime('%s%L').to_i
    end

    def canonicalize
      sb = "#{user&.user_id&.strip} #{user&.device_id&.strip} "
      results.sort.to_h.each do |key, value|
        sb += "#{key.strip} #{value&.fetch(:value)&.strip} "
      end
      sb
    end
  end
end
