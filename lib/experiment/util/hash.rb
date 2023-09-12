# AmplitudeExperiment
module AmplitudeExperiment
  def self.hash_code(string)
    hash = 0
    return hash if string.empty?

    string.each_char do |char|
      chr_code = char.ord
      hash = ((hash << 5) - hash) + chr_code
      hash &= 0xFFFFFFFF
    end

    hash
  end
end
