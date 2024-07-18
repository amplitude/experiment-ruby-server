module AmplitudeExperiment
  def self.topological_sort(flags, keys = nil, ordered = false)
    available = flags.dup
    result = []
    starting_keys = keys.nil? || keys.empty? ? flags.keys : keys
    # Used for testing to ensure consistency.
    starting_keys.sort! if ordered && (keys.nil? || keys.empty?)

    starting_keys.each do |flag_key|
      traversal = parent_traversal(flag_key, available, Set.new)
      result.concat(traversal) unless traversal.nil?
    end
    result
  end

  def self.parent_traversal(flag_key, available, path)
    flag = available[flag_key]
    return nil if flag.nil?

    dependencies = flag[:dependencies]
    if dependencies.nil? || dependencies.empty?
      available.delete(flag_key)
      return [flag]
    end

    path.add(flag_key)
    result = []
    dependencies.each do |parent_key|
      raise CycleError.new(path) if path.include?(parent_key)

      traversal = parent_traversal(parent_key, available, path)
      result.concat(traversal) unless traversal.nil?
    end
    result << flag
    path.delete(flag_key)
    available.delete(flag_key)
    result
  end
end
