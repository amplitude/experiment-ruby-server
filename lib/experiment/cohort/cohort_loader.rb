module AmplitudeExperiment
  # CohortLoader
  class CohortLoader
    def initialize(cohort_download_api, cohort_storage)
      @cohort_download_api = cohort_download_api
      @cohort_storage = cohort_storage
      @jobs = {}
      @lock_jobs = Mutex.new
      @executor = Concurrent::ThreadPoolExecutor.new(
        max_threads: 32,
        name: 'CohortLoaderExecutor'
      )
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

    def update_stored_cohorts
      errors = []

      Concurrent::Promises.future_on(@executor) do
        futures = @cohort_storage.cohort_ids.map do |cohort_id|
          Concurrent::Promises.future_on(@executor) do
            load_cohort_internal(cohort_id)
          rescue StandardError => e
            [cohort_id, e] # Return the cohort_id and the error
          end
        end

        results = Concurrent::Promises.zip(*futures).value!

        # Collect errors from the results
        results.each do |result|
          errors << result if result.is_a?(Array) && result[1].is_a?(StandardError)
        end

        raise CohortUpdateError, errors unless errors.empty?
      end
    end

    private

    def load_cohort_internal(cohort_id)
      stored_cohort = @cohort_storage.cohort(cohort_id)
      updated_cohort = @cohort_download_api.get_cohort(cohort_id, stored_cohort)
      @cohort_storage.put_cohort(updated_cohort)
    end

    def remove_job(cohort_id)
      @lock_jobs.synchronize do
        @jobs.delete(cohort_id)
      end
    end
  end
end
