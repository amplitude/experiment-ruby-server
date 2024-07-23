module AmplitudeExperiment
  def self.user_to_evaluation_context(user)
    user_groups = user.groups
    user_group_properties = user.group_properties
    user_group_cohort_ids = user.group_cohort_ids
    user_hash = user.as_json.compact
    user_hash.delete('groups')
    user_hash.delete('group_properties')
    user_hash.delete('group_cohort_ids')

    context = user_hash.empty? ? {} : { 'user' => user_hash }

    return context if user_groups.nil?

    groups = {}
    user_groups.each do |group_type, group_name|
      group_name = group_name[0] if group_name.is_a?(Array) && !group_name.empty?

      groups[group_type] = { 'group_name' => group_name }

      if user_group_properties
        group_properties_type = user_group_properties[group_type]
        if group_properties_type.is_a?(Hash)
          group_properties_name = group_properties_type[group_name]
          groups[group_type]['group_properties'] = group_properties_name if group_properties_name.is_a?(Hash)
        end
      end

      next unless user_group_cohort_ids

      group_cohort_ids_type = user_group_cohort_ids[group_type]
      if group_cohort_ids_type.is_a?(Hash)
        group_cohort_ids_name = group_cohort_ids_type[group_name]
        groups[group_type]['cohort_ids'] = group_cohort_ids_name if group_cohort_ids_name.is_a?(Array)
      end
    end

    context['groups'] = groups unless groups.empty?
    context
  end
end
