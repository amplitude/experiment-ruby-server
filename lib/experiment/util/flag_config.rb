module AmplitudeExperiment
  def self.cohort_filter?(condition)
    ['set contains any', 'set does not contain any'].include?(condition['op']) &&
      condition['selector'] &&
      condition['selector'][-1] == 'cohort_ids'
  end

  def self.get_grouped_cohort_condition_ids(segment)
    cohort_ids = {}
    conditions = segment['conditions'] || []
    conditions.each do |condition|
      condition = condition[0]
      next unless cohort_filter?(condition) && (condition['selector'][1].length > 2)

      context_subtype = condition['selector'][1]
      group_type =
        if context_subtype == 'user'
          USER_GROUP_TYPE
        elsif condition['selector'].include?('groups')
          condition['selector'][2]
        else
          next
        end
      cohort_ids[group_type] ||= Set.new
      cohort_ids[group_type].merge(condition['values'])
    end
    cohort_ids
  end

  def self.get_grouped_cohort_ids_from_flag(flag)
    cohort_ids = {}
    segments = flag['segments'] || []
    segments.each do |segment|
      get_grouped_cohort_condition_ids(segment).each do |key, values|
        cohort_ids[key] ||= Set.new
        cohort_ids[key].merge(values)
      end
    end
    cohort_ids
  end

  def self.get_all_cohort_ids_from_flag(flag)
    get_grouped_cohort_ids_from_flag(flag).values.reduce(Set.new) { |acc, set| acc.merge(set) }
  end

  def self.get_grouped_cohort_ids_from_flags(flags)
    cohort_ids = {}
    flags.each do |_, flag|
      get_grouped_cohort_ids_from_flag(flag).each do |key, values|
        cohort_ids[key] ||= Set.new
        cohort_ids[key].merge(values)
      end
    end
    cohort_ids
  end

  def self.get_all_cohort_ids_from_flags(flags)
    get_grouped_cohort_ids_from_flags(flags).values.reduce(Set.new) { |acc, set| acc.merge(set) }
  end
end
