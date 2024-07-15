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
        start_flag_poller
        start_cohort_poller if @cohort_loader
      end
    end

    def stop
      stop_flag_poller
      stop_cohort_poller
    end

    private

    def start_flag_poller
      @flag_poller = Poller.new(
        @config.flag_config_polling_interval_millis / 1000.0,
        method(:periodic_flag_update)
      )
      @flag_poller.start
    end

    def stop_flag_poller
      @flag_poller&.stop
      @flag_poller = nil
    end

    def start_cohort_poller
      @cohort_poller = Poller.new(
        @config.flag_config_polling_interval_millis / 1000.0,
        method(:update_cohorts)
      )
      @cohort_poller.start
    end

    def stop_cohort_poller
      @cohort_poller&.stop
      @cohort_poller = nil
    end

    def periodic_flag_update
      update_flag_configs
    rescue StandardError => e
      @logger.error("Error while updating flags: #{e}")

    end

    def update_flag_configs
      flag_configs = @flag_config_fetcher.fetch_v1

      flag_keys = flag_configs.map { |flag| flag['key'] }.to_set
      @flag_config_storage.remove_if { |f| !flag_keys.include?(f['key']) }

      unless @cohort_loader
        flag_configs.each do |flag_config|
          @logger.debug("Putting non-cohort flag #{flag_config['key']}")
          @flag_config_storage.put_flag_config(flag_config)
        end
        return
      end

      new_cohort_ids = Set.new
      flag_configs.each do |flag_config|
        new_cohort_ids.merge(get_all_cohort_ids_from_flag(flag_config))
      end

      existing_cohort_ids = @cohort_storage.get_cohort_ids
      cohort_ids_to_download = new_cohort_ids - existing_cohort_ids
      cohort_download_errors = []

      cohort_ids_to_download.each do |cohort_id|

        @cohort_loader.load_cohort(cohort_id).result
      rescue StandardError => e
        cohort_download_errors << [cohort_id, e.to_s]
        @logger.error("Download cohort #{cohort_id} failed: #{e}")

      end

      updated_cohort_ids = @cohort_storage.get_cohort_ids
      failed_flag_count = 0

      flag_configs.each do |flag_config|
        cohort_ids = get_all_cohort_ids_from_flag(flag_config)
        if cohort_ids.empty? || !@cohort_loader
          @flag_config_storage.put_flag_config(flag_config)
          @logger.debug("Putting non-cohort flag #{flag_config['key']}")
        elsif cohort_ids.subset?(updated_cohort_ids)
          @flag_config_storage.put_flag_config(flag_config)
          @logger.debug("Putting flag #{flag_config['key']}")
        else
          @logger.error("Flag #{flag_config['key']} not updated because not all required cohorts could be loaded")
          failed_flag_count += 1
        end
      end

      _delete_unused_cohorts
      @logger.debug("Refreshed #{flag_configs.size - failed_flag_count} flag configs.")

      unless cohort_download_errors.empty?
        error_count = cohort_download_errors.size
        error_messages = cohort_download_errors.map { |cohort_id, error| "Cohort #{cohort_id}: #{error}" }.join("\n")
        raise "#{error_count} cohort(s) failed to download:\n#{error_messages}"
      end
    rescue StandardError => e
      @logger.error("Failed to fetch flag configs: #{e}")
      raise e
    end

    def update_cohorts
      @cohort_loader.update_stored_cohorts.result
    rescue StandardError => e
      @logger.error("Error while updating cohorts: #{e}")
    end

    def _delete_unused_cohorts
      flag_cohort_ids = Set.new
      @flag_config_storage.flag_configs.each do |flag|
        flag_cohort_ids.merge(get_all_cohort_ids_from_flag(flag))
      end

      storage_cohorts = @cohort_storage.get_cohorts
      deleted_cohort_ids = storage_cohorts.keys - flag_cohort_ids

      deleted_cohort_ids.each do |deleted_cohort_id|
        deleted_cohort = storage_cohorts[deleted_cohort_id]
        if deleted_cohort
          @cohort_storage.delete_cohort(deleted_cohort.group_type, deleted_cohort_id)
        end
      end
    end
  end
end
