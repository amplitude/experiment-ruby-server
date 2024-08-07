module AmplitudeExperiment
  # CohortLoader
  class CohortLoader
    def initialize(cohort_download_api, cohort_storage)
      @cohort_download_api = cohort_download_api
      @cohort_storage = cohort_storage
      @jobs = {}
      @lock_jobs = Mutex.new
    end

    def load_cohort(cohort_id)
      @lock_jobs.synchronize do
        unless @jobs.key?(cohort_id)
          future = Concurrent::Promises.future do
            load_cohort_internal(cohort_id)
          ensure
            remove_job(cohort_id)
          end
          @jobs[cohort_id] = future
        end
        @jobs[cohort_id]
      end
    end

    private

    def load_cohort_internal(cohort_id)
      stored_cohort = @cohort_storage.cohort(cohort_id)
      updated_cohort = @cohort_download_api.get_cohort(cohort_id, stored_cohort)
      @cohort_storage.put_cohort(updated_cohort) unless updated_cohort.nil?
    end

    def remove_job(cohort_id)
      @lock_jobs.synchronize do
        @jobs.delete(cohort_id)
      end
    end
  end
end
