require 'time'
require 'logger'
require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'set'

module AmplitudeExperiment
  # CohortDownloadApi
  class CohortDownloadApi
    def get_cohort(cohort_id, cohort = nil)
      raise NotImplementedError
    end
  end

  # DirectCohortDownloadApi
  class DirectCohortDownloadApi < CohortDownloadApi
    def initialize(api_key, secret_key, max_cohort_size, cohort_request_delay_millis, server_url, logger)
      super()
      @api_key = api_key
      @secret_key = secret_key
      @max_cohort_size = max_cohort_size
      @cohort_request_delay_millis = cohort_request_delay_millis
      @server_url = server_url
      @logger = logger
      @http = PersistentHttpClient.get(server_url, { read_timeout: cohort_request_delay_millis }, api_key)
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
            raise CohortNotModifiedError, "Cohort not modified: #{response.code}"
          when 413
            raise CohortTooLargeError, "Cohort exceeds max cohort size: #{response.code}"
          else
            raise HTTPErrorResponseError.new(response.code, "Unexpected response code: #{response.code}") if response.code.to_i != 202

          end
        rescue StandardError => e
          errors += 1 unless response && e.is_a?(HTTPErrorResponseError) && response.code.to_i == 429
          @logger.debug("getCohortMembers(#{cohort_id}): request-status error #{errors} - #{e}")
          raise e if errors >= 3 || e.is_a?(CohortNotModifiedError) || e.is_a?(CohortTooLargeError)
        end

        sleep(@cohort_request_delay_millis / 1000.0)
      end
    end

    private

    def get_cohort_members_request(cohort_id, last_modified)
      headers = {
        'Authorization' => "Basic #{basic_auth}",
        'Content-Type' => 'application/json;charset=utf-8'
      }
      url = "#{@server_url}/sdk/v1/cohort/#{cohort_id}?maxCohortSize=#{@max_cohort_size}"
      url += "&lastModified=#{last_modified}" if last_modified

      request = Net::HTTP::Get.new(url, headers)
      @http.request(request)
    end

    def basic_auth
      credentials = "#{@api_key}:#{@secret_key}"
      Base64.strict_encode64(credentials)
    end
  end
end
