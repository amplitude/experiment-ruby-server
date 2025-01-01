# frozen_string_literal: true

class CycleError < StandardError
  attr_accessor :path
  def initialize(path)
    super("Detected a cycle between flags #{path}")
    self.path = path
  end
end

# Performs topological sorting of feature flags based on their dependencies
class TopologicalSort
  # Sort flags topologically based on their dependencies
  def self.sort(flags, flag_keys = nil)
    available = flags.clone
    result = []
    starting_keys = flag_keys == nil || flag_keys.length == 0 ? flags.keys : flag_keys

    starting_keys.each do |flag_key|
      traversal = parent_traversal(flag_key, available)
      result.concat(traversal) if traversal
    end

    result
  end

  private

  # Perform depth-first traversal of flag dependencies
  def self.parent_traversal(flag_key, available, path = [])
    flag = available[flag_key]
    return nil unless flag

    # No dependencies - return flag and remove from available
    if !flag.dependencies || flag.dependencies.empty?
      available.delete(flag.key)
      return [flag]
    end

    # Check for cycles
    path.push(flag.key)
    result = []

    flag.dependencies.each do |parent_key|
      if path.any? { |p| p == parent_key }
        raise CycleError, path
      end

      traversal = parent_traversal(parent_key, available, path)
      result.concat(traversal) if traversal
    end

    result.push(flag)
    path.pop
    available.delete(flag.key)

    result
  end
end
