require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'set'

module AmplitudeExperiment
  # CohortDownloadApi
  class CohortDownloadApi
    COHORT_REQUEST_TIMEOUT_MILLIS = 5000
    COHORT_REQUEST_RETRY_DELAY_MILLIS = 100

    def get_cohort(cohort_id, cohort = nil)
      raise NotImplementedError
    end
  end

  # DirectCohortDownloadApi
  class DirectCohortDownloadApi < CohortDownloadApi
    def initialize(api_key, secret_key, max_cohort_size, server_url, logger)
      super()
      @api_key = api_key
      @secret_key = secret_key
      @max_cohort_size = max_cohort_size
      @server_url = server_url
      @logger = logger
    end

    def get_cohort(cohort_id, cohort = nil)
      @logger.debug("getCohortMembers(#{cohort_id}): start")
      errors = 0

      loop do
        begin
          last_modified = cohort.nil? ? nil : cohort.last_modified
          response = get_cohort_members_request(cohort_id, last_modified)
          @logger.debug("getCohortMembers(#{cohort_id}): status=#{response.code}")

          case response.code.to_i
          when 200
            cohort_info = JSON.parse(response.body)
            @logger.debug("getCohortMembers(#{cohort_id}): end - resultSize=#{cohort_info['size']}")
            return Cohort.new(
              cohort_info['cohortId'],
              cohort_info['lastModified'],
              cohort_info['size'],
              cohort_info['memberIds'].to_set,
              cohort_info['groupType']
            )
          when 204
            @logger.debug("getCohortMembers(#{cohort_id}): Cohort not modified")
            return nil
          when 413
            raise CohortTooLargeError.new(cohort_id, "Cohort exceeds max cohort size: #{response.code}")
          else
            raise HTTPErrorResponseError.new(response.code, cohort_id, "Unexpected response code: #{response.code}") if response.code.to_i != 202

          end
        rescue StandardError => e
          errors += 1 unless response && e.is_a?(HTTPErrorResponseError) && response.code.to_i == 429
          @logger.debug("getCohortMembers(#{cohort_id}): request-status error #{errors} - #{e}")
          raise e if errors >= 3 || e.is_a?(CohortTooLargeError)
        end

        sleep(COHORT_REQUEST_RETRY_DELAY_MILLIS / 1000.0)
      end
    end

    private

    def get_cohort_members_request(cohort_id, last_modified)
      headers = {
        'Authorization' => "Basic #{basic_auth}",
        'Content-Type' => 'application/json;charset=utf-8',
        'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}"
      }
      url = "#{@server_url}/sdk/v1/cohort/#{cohort_id}?maxCohortSize=#{@max_cohort_size}"
      url += "&lastModified=#{last_modified}" if last_modified

      request = Net::HTTP::Get.new(URI(url), headers)
      http = PersistentHttpClient.get(@server_url, { read_timeout: COHORT_REQUEST_TIMEOUT_MILLIS }, basic_auth)
      http.request(request)
    end

    def basic_auth
      credentials = "#{@api_key}:#{@secret_key}"
      Base64.strict_encode64(credentials)
    end
  end
end
