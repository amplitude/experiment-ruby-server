require_relative './cohort'

module AmplitudeExperiment
  # CohortStorage
  class CohortStorage
    def get_cohort(cohort_id)
      raise NotImplementedError
    end

    def cohorts
      raise NotImplementedError
    end

    def get_cohorts_for_user(user_id, cohort_ids)
      raise NotImplementedError
    end

    def get_cohorts_for_group(group_type, group_name, cohort_ids)
      raise NotImplementedError
    end

    def put_cohort(cohort_description)
      raise NotImplementedError
    end

    def delete_cohort(group_type, cohort_id)
      raise NotImplementedError
    end

    def cohort_ids
      raise NotImplementedError
    end
  end

  class InMemoryCohortStorage < CohortStorage
    def initialize
      super
      @lock = Mutex.new
      @group_to_cohort_store = {}
      @cohort_store = {}
    end

    def get_cohort(cohort_id)
      @lock.synchronize do
        @cohort_store[cohort_id]
      end
    end

    def cohorts
      @lock.synchronize do
        @cohort_store.dup
      end
    end

    def get_cohorts_for_user(user_id, cohort_ids)
      get_cohorts_for_group(USER_GROUP_TYPE, user_id, cohort_ids)
    end

    def get_cohorts_for_group(group_type, group_name, cohort_ids)
      result = Set.new
      @lock.synchronize do
        group_type_cohorts = @group_to_cohort_store[group_type] || Set.new
        group_type_cohorts.each do |cohort_id|
          members = @cohort_store[cohort_id]&.member_ids || Set.new
          result.add(cohort_id) if cohort_ids.include?(cohort_id) && members.include?(group_name)
        end
      end
      result
    end

    def put_cohort(cohort)
      @lock.synchronize do
        @group_to_cohort_store[cohort.group_type] ||= Set.new
        @group_to_cohort_store[cohort.group_type].add(cohort.id)
        @cohort_store[cohort.id] = cohort
      end
    end

    def delete_cohort(group_type, cohort_id)
      @lock.synchronize do
        group_cohorts = @group_to_cohort_store[group_type] || Set.new
        group_cohorts.delete(cohort_id)
        @cohort_store.delete(cohort_id)
      end
    end

    def cohort_ids
      @lock.synchronize do
        @cohort_store.keys.to_set
      end
    end
  end
end
