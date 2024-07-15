require 'json'
require 'logger'
require 'rspec'
require 'webmock/rspec'

module AmplitudeExperiment
  SERVER_URL = 'https://example.amplitude.com'.freeze
  API_KEY = 'api'.freeze
  SECRET_KEY = 'secret'.freeze
  MAX_COHORT_SIZE = 15_000
  COHORT_REQUEST_DELAY_MILLIS = 100

  RSpec.describe CohortDownloadApi do
    let(:logger) { Logger.new($stdout) }
    let(:api) do
      DirectCohortDownloadApi.new(
        API_KEY,
        SECRET_KEY,
        MAX_COHORT_SIZE,
        COHORT_REQUEST_DELAY_MILLIS,
        SERVER_URL,
        logger
      )
    end

    def response(code, body = nil)
      {
        status: code,
        body: body.nil? ? '' : JSON.dump(body),
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    def cohort_to_h(cohort)
      {
        cohortId: cohort.id,
        lastModified: cohort.last_modified,
        size: cohort.size,
        groupType: cohort.group_type,
        memberIds: cohort.member_ids
      }
    end

    describe '#get_cohort' do
      let(:cohort_id) { '1234' }

      it 'downloads cohort successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        cohort_info_response = {
          cohortId: cohort_id,
          lastModified: 0,
          size: 1,
          groupType: 'User',
          memberIds: ['user']
        }

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(status: 200, body: JSON.dump(cohort_info_response))

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort.id).to eq(cohort.id)
        expect(result_cohort.last_modified).to eq(cohort.last_modified)
        expect(result_cohort.size).to eq(cohort.size)
        expect(result_cohort.member_ids).to eq(cohort.member_ids)
      end

      it 'handles many 202 responses successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        async_responses = ([response(202)] * 9) + [response(200, { cohortId: '1234', lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })]

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(async_responses)

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort.id).to eq(cohort.id)
        expect(result_cohort.last_modified).to eq(cohort.last_modified)
        expect(result_cohort.size).to eq(cohort.size)
        expect(result_cohort.member_ids).to eq(cohort.member_ids)
      end

      it 'handles request status with two failures successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        error_response = response(503)
        success_response = response(200, { cohortId: cohort_id, lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })
        async_responses = [error_response, error_response, success_response]

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(async_responses)

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort).to eq(cohort)
      end

      it 'handles 429s and retries successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        error_response = response(429)
        success_response = response(200, { cohortId: cohort_id, lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })
        async_responses = ([error_response] * 9) + [success_response]

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(async_responses)

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort).to eq(cohort)
      end

      it 'handles group cohort download successfully' do
        cohort_id = '1234'
        group_name = 'User'
        cohort = Cohort.new(cohort_id, 0, 1, ['group'], group_name)

        cohort_info_response = {
          'cohortId' => cohort_id,
          'lastModified' => 0,
          'size' => 1,
          'memberIds' => ['group'],
          'groupType' => group_name
        }

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(status: 200, body: JSON.dump(cohort_info_response))

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort.id).to eq(cohort.id)
        expect(result_cohort.last_modified).to eq(cohort.last_modified)
        expect(result_cohort.size).to eq(cohort.size)
        expect(result_cohort.member_ids).to eq(cohort.member_ids)
        expect(result_cohort.group_type).to eq(cohort.group_type)
      end


      it 'retries on 429s for group cohort request' do
        group_name = 'org name'
        cohort = Cohort.new(cohort_id, 0, 1, ['group'], group_name)
        error_response = response(429)
        success_response = response(200, { cohortId: cohort_id, lastModified: 0, size: 1, groupType: group_name, memberIds: ['group'] })
        async_responses = ([error_response] * 9) + [success_response]

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(async_responses)

        result_cohort = api.get_cohort(cohort_id, cohort)
        expect(result_cohort).to eq(cohort)
      end

      it 'raises CohortTooLargeError for too large cohort size' do
        cohort = Cohort.new(cohort_id, nil, 16_000, [])

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(status: 413)

        expect { api.get_cohort(cohort_id, cohort) }.to raise_error(CohortTooLargeError)
      end


      it 'raises CohortNotModifiedError for cohort not modified' do
        last_modified = 1000
        cohort = Cohort.new(cohort_id, last_modified, 1, [])

        stub_request(:get, "#{SERVER_URL}/sdk/v1/cohort/#{cohort_id}?lastModified=#{last_modified}&maxCohortSize=#{MAX_COHORT_SIZE}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Basic YXBpOnNlY3JldA==',
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          )
          .to_return(response(204))

        expect { api.get_cohort(cohort_id, cohort) }.to raise_error(CohortNotModifiedError)
      end
    end
  end
end
