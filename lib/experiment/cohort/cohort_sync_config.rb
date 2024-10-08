module AmplitudeExperiment
  DEFAULT_COHORT_SYNC_URL = 'https://cohort-v2.lab.amplitude.com'.freeze
  EU_COHORT_SYNC_URL = 'https://cohort-v2.lab.eu.amplitude.com'.freeze

  # Experiment Cohort Sync Configuration
  class CohortSyncConfig
    # This configuration is used to set up the cohort loader. The cohort loader is responsible for
    # downloading cohorts from the server and storing them locally.
    #   Parameters:
    #     api_key (str): The project API Key
    #     secret_key (str): The project Secret Key
    #     max_cohort_size (int): The maximum cohort size that can be downloaded
    #     cohort_polling_interval_millis (int): The interval in milliseconds to poll for cohorts, the minimum value is 60000
    #     cohort_server_url (str): The server endpoint from which to request cohorts

    attr_accessor :api_key, :secret_key, :max_cohort_size, :cohort_polling_interval_millis, :cohort_server_url

    def initialize(api_key, secret_key, max_cohort_size: 2_147_483_647, cohort_polling_interval_millis: 60_000,
                   cohort_server_url: DEFAULT_COHORT_SYNC_URL)
      @api_key = api_key
      @secret_key = secret_key
      @max_cohort_size = max_cohort_size
      @cohort_polling_interval_millis = [cohort_polling_interval_millis, 60_000].max
      @cohort_server_url = cohort_server_url
    end
  end
end
