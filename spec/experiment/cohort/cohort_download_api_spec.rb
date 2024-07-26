require 'json'
require 'logger'
require 'rspec'
require 'webmock/rspec'

module AmplitudeExperiment
  RSpec.describe AmplitudeExperiment::CohortDownloadApi do
    let(:logger) { Logger.new($stdout) }
    let(:api_key) { 'api' }
    let(:secret_key) { 'secret' }
    let(:server_url) { 'https://example.amplitude.com' }
    let(:max_cohort_size) { 15_000 }
    let(:cohort_request_delay_millis) { 100 }
    let(:api) { AmplitudeExperiment::DirectCohortDownloadApi.new(api_key, secret_key, max_cohort_size, cohort_request_delay_millis, server_url, logger) }

    def response(code, body = nil)
      { status: code, body: body.nil? ? '' : JSON.dump(body), headers: { 'Content-Type' => 'application/json' } }
    end

    describe '#get_cohort' do
      let(:cohort_id) { '1234' }
      let(:headers) do
        {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Basic YXBpOnNlY3JldA==',
          'Content-Type' => 'application/json;charset=utf-8',
          'User-Agent' => 'Ruby'
        }
      end

      it 'downloads cohort successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        cohort_info = { cohortId: cohort_id, lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] }

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(status: 200, body: JSON.dump(cohort_info))

        result = api.get_cohort(cohort_id, cohort)
        expect(result).to have_attributes(id: cohort.id, last_modified: cohort.last_modified, size: cohort.size, member_ids: cohort.member_ids)
      end

      it 'handles many 202 responses successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        async_responses = ([response(202)] * 9) + [response(200, { cohortId: '1234', lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })]

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(async_responses)

        result = api.get_cohort(cohort_id, cohort)
        expect(result).to have_attributes(id: cohort.id, last_modified: cohort.last_modified, size: cohort.size, member_ids: cohort.member_ids)
      end

      it 'handles request status with two failures successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        responses = [response(503), response(503), response(200, { cohortId: cohort_id, lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })]

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(responses)

        result = api.get_cohort(cohort_id, cohort)
        expect(result).to eq(cohort)
      end

      it 'handles 429s and retries successfully' do
        cohort = Cohort.new(cohort_id, 0, 1, ['user'])
        responses = ([response(429)] * 9) + [response(200, { cohortId: cohort_id, lastModified: 0, size: 1, groupType: 'User', memberIds: ['user'] })]

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(responses)

        result = api.get_cohort(cohort_id, cohort)
        expect(result).to eq(cohort)
      end

      it 'handles group cohort download successfully' do
        group_name = 'User'
        cohort = Cohort.new(cohort_id, 0, 1, ['group'], group_name)
        cohort_info = { cohortId: cohort_id, lastModified: 0, size: 1, memberIds: ['group'], groupType: group_name }

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=0&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(status: 200, body: JSON.dump(cohort_info))

        result = api.get_cohort(cohort_id, cohort)
        expect(result).to have_attributes(id: cohort.id, last_modified: cohort.last_modified, size: cohort.size, member_ids: cohort.member_ids, group_type: cohort.group_type)
      end

      it 'raises CohortTooLargeError for too large cohort size' do
        cohort = Cohort.new(cohort_id, nil, 16_000, [])

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(status: 413)

        expect { api.get_cohort(cohort_id, cohort) }.to raise_error(CohortTooLargeError)
      end

      it 'raises CohortNotModifiedError for cohort not modified' do
        last_modified = 1000
        cohort = Cohort.new(cohort_id, last_modified, 1, [])

        stub_request(:get, "#{server_url}/sdk/v1/cohort/#{cohort_id}?lastModified=#{last_modified}&maxCohortSize=#{max_cohort_size}")
          .with(headers: headers).to_return(response(204))

        expect { api.get_cohort(cohort_id, cohort) }.to raise_error(CohortNotModifiedError)
      end
    end
  end
end
