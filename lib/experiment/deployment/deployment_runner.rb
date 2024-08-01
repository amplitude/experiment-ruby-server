require 'set'

module AmplitudeExperiment
  # DeploymentRunner
  class DeploymentRunner
    def initialize(
      config,
      flag_config_fetcher,
      flag_config_storage,
      cohort_storage,
      logger,
      cohort_loader = nil
    )
      @config = config
      @flag_config_fetcher = flag_config_fetcher
      @flag_config_storage = flag_config_storage
      @cohort_storage = cohort_storage
      @cohort_loader = cohort_loader
      @lock = Mutex.new
      @logger = logger
    end

    def start
      @lock.synchronize do
        update_flag_configs
        @flag_poller = Poller.new(
          @config.flag_config_polling_interval_millis / 1000.0,
          method(:periodic_flag_update)
        )
        @flag_poller.start
        if @cohort_loader
          @cohort_poller = Poller.new(
            @config.flag_config_polling_interval_millis / 1000.0,
            method(:update_cohorts)
          )
          @cohort_poller.start
        end
      end
    end

    def stop
      @flag_poller&.stop
      @flag_poller = nil
      @cohort_poller&.stop
      @cohort_poller = nil
    end

    private

    def periodic_flag_update
      update_flag_configs
    rescue StandardError => e
      @logger.error("Error while updating flags: #{e}")
    end

    def update_flag_configs
      flags = @flag_config_fetcher.fetch_v2
      flag_configs = flags.each_with_object({}) { |flag, hash| hash[flag['key']] = flag }
      flag_keys = flag_configs.values.map { |flag| flag['key'] }.to_set
      @flag_config_storage.remove_if { |f| !flag_keys.include?(f['key']) }

      unless @cohort_loader
        flag_configs.each do |flag_config|
          flag_config = flag_config[1]
          @logger.debug("Putting non-cohort flag #{flag_config['key']}")
          @flag_config_storage.put_flag_config(flag_config)
        end
        return
      end

      new_cohort_ids = Set.new
      flag_configs.each do |flag_config|
        flag_config = flag_config[1]
        new_cohort_ids.merge(AmplitudeExperiment.get_all_cohort_ids_from_flag(flag_config))
      end

      existing_cohort_ids = @cohort_storage.cohort_ids
      cohort_ids_to_download = new_cohort_ids - existing_cohort_ids

      futures = cohort_ids_to_download.map do |cohort_id|
        future = @cohort_loader.load_cohort(cohort_id)
        future.on_rejection do |reason|
          @logger.warn("Download cohort #{cohort_id} failed: #{reason}")
        end
        future
      end

      begin
        Concurrent::Promises.zip(*futures).value!
      rescue StandardError => e
        @logger.error("Failed to download cohorts: #{e}")
      end

      updated_cohort_ids = @cohort_storage.cohort_ids

      flag_configs.each do |flag_key, flag_config|
        cohort_ids = AmplitudeExperiment.get_all_cohort_ids_from_flag(flag_config)
        @logger.debug("Storing flag #{flag_key}")
        @flag_config_storage.put_flag_config(flag_config)
        missing_cohorts = cohort_ids - updated_cohort_ids

        @logger.warn("Flag #{flag_key} - failed to load cohorts: #{missing_cohorts}") if missing_cohorts.any?
      end

      delete_unused_cohorts
      @logger.debug("Refreshed #{flag_configs.size} flag configs.")
    end

    def update_cohorts
      @cohort_loader.update_stored_cohorts.value!
    rescue StandardError => e
      @logger.error("Error while updating cohorts: #{e}")
    end

    def delete_unused_cohorts
      flag_cohort_ids = Set.new
      @flag_config_storage.flag_configs.each do |_, flag|
        flag_cohort_ids.merge(AmplitudeExperiment.get_all_cohort_ids_from_flag(flag))
      end

      storage_cohorts = @cohort_storage.cohorts
      deleted_cohort_ids = storage_cohorts.keys.to_set - flag_cohort_ids

      deleted_cohort_ids.each do |deleted_cohort_id|
        deleted_cohort = storage_cohorts[deleted_cohort_id]
        @cohort_storage.delete_cohort(deleted_cohort.group_type, deleted_cohort_id) if deleted_cohort
      end
    end
  end
end