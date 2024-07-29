module AmplitudeExperiment
  def self.user_to_evaluation_context(user)
    user_groups = user.groups
    user_group_properties = user.group_properties
    user_hash = user.as_json.compact
    user_hash.delete(:groups)
    user_hash.delete(:group_properties)

    context = user_hash.empty? ? {} : { user: user_hash }

    return context if user_groups.nil?

    groups = {}
    user_groups.each do |group_type, group_name|
      group_name = group_name[0] if group_name.is_a?(Array) && !group_name.empty?

      groups[group_type.to_sym] = { group_name: group_name }

      next if user_group_properties.nil?

      group_properties_type = user_group_properties[group_type.to_sym]
      next if group_properties_type.nil? || !group_properties_type.is_a?(Hash)

      group_properties_name = group_properties_type[group_name.to_sym]
      next if group_properties_name.nil? || !group_properties_name.is_a?(Hash)

      groups[group_type.to_sym][:group_properties] = group_properties_name
    end

    context[:groups] = groups unless groups.empty?
    context
  end
end
