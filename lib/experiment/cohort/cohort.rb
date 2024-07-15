module AmplitudeExperiment
  USER_GROUP_TYPE = 'User'.freeze
  # Cohort
  class Cohort
    attr_accessor :id, :last_modified, :size, :member_ids, :group_type

    def initialize(id, last_modified, size, member_ids, group_type = USER_GROUP_TYPE)
      @id = id
      @last_modified = last_modified
      @size = size
      @member_ids = member_ids.to_set
      @group_type = group_type
    end

    def ==(other)
      return false unless other.is_a?(Cohort)

      @id == other.id &&
        @last_modified == other.last_modified &&
        @size == other.size &&
        @member_ids == other.member_ids &&
        @group_type == other.group_type
    end
  end
end
