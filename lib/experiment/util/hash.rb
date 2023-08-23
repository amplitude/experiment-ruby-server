# AmplitudeExperiment
module AmplitudeExperiment
  def self.hash_code(string)
    hash = 0
    return hash if string.empty?

    string.each_char do |chr|
      hash = (hash << 5) - hash + chr.ord
      hash |= 0
    end

    hash
  end
end
