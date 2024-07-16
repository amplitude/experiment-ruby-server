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
        begin
          futures = @cohort_storage.cohort_ids.map do |cohort_id|
            Concurrent::Promises.future_on(@executor) do
              load_cohort_internal(cohort_id)
            end
          end

          futures.each do |future|
            future.rescue do |e|
              errors << [future.value!, e]
            end
          end
          Concurrent::Promises.zip(*futures).value!
        rescue StandardError => e
          errors << e
        end

        raise CohortUpdateError, errors unless errors.empty?
      end
    end

    private

    def load_cohort_internal(cohort_id)
      cohort = @cohort_download_api.get_cohort(cohort_id)
      @cohort_storage.put_cohort(cohort)
    end

    def remove_job(cohort_id)
      @lock_jobs.synchronize do
        @jobs.delete(cohort_id)
      end
    end
  end
end
