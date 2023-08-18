require 'spec_helper'
require_relative '../../../lib/amplitude'

module AmplitudeExperiment
  LOCAL_SERVER_URL = 'https://api.lab.amplitude.com/sdk/vardata'.freeze
  TEST_USER = User.new(user_id: 'test_user')
  TEST_USER_2 = User.new(user_id: 'user_id', device_id: 'device_id')

  describe LocalEvaluationClient do
    def setup_stub
      response = '[{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"holdout":1,"on":99}}],"bucketingGroupType":null,"bucketingKey":"device_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"nI33zio8","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":false,"enabled":true,"experimentKey":null,"flagKey":"holdout-sdk-ci-local-dependencies-test-holdout","flagVersion":1,"parentDependencies":null,"type":"holdout-group","variants":[{"key":"holdout","payload":{"flagIds":[]}},{"key":"on","payload":{"flagIds":["42953"]}}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"slot-1":100,"unallocated":0}}],"bucketingGroupType":null,"bucketingKey":"device_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"sVlTAPmD","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":false,"enabled":true,"experimentKey":null,"flagKey":"mutex-sdk-ci-local-dependencies-test-mutex","flagVersion":1,"parentDependencies":null,"type":"mutual-exclusion-group","variants":[{"key":"unallocated","payload":{"flagIds":[]}},{"key":"slot-1","payload":{"flagIds":["42953"]}}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"control":1,"treatment":0}}],"bucketingGroupType":null,"bucketingKey":"device_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"ne4upNtg","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":true,"enabled":true,"experimentKey":"exp-1","flagKey":"sdk-ci-local-dependencies-test","flagVersion":9,"parentDependencies":{"flags":{"holdout-sdk-ci-local-dependencies-test-holdout":["on"],"mutex-sdk-ci-local-dependencies-test-mutex":["slot-1"]},"operator":"ALL"},"type":"experiment","variants":[{"key":"control","payload":null},{"key":"treatment","payload":null}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":0,"weights":{"on":1}}],"bucketingGroupType":null,"bucketingKey":"user_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"e4BrRQzR","customSegmentTargetingConfigs":[{"allocations":[{"percentage":10000,"weights":{"on":1}}],"bucketingGroupType":null,"bucketingKey":"user_id","conditions":[{"op":"IS","prop":"userdata_cohort","values":["ursx46e","mg7og2z"]}],"name":"Segment 1"}],"defaultValue":"off","deployed":true,"enabled":true,"experimentKey":null,"flagKey":"sdk-cohort-ci-test","flagVersion":29,"parentDependencies":null,"type":"release","variants":[{"key":"on","payload":null}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"on":1}}],"bucketingGroupType":null,"bucketingKey":"user_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"LM8tqPRS","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":true,"enabled":true,"experimentKey":null,"flagKey":"sdk-local-evaluation-ci-test","flagVersion":7,"parentDependencies":null,"type":"release","variants":[{"key":"on","payload":"payload"}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"holdout":99,"on":1}}],"bucketingGroupType":null,"bucketingKey":"device_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"ubvfZywq","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":false,"enabled":true,"experimentKey":null,"flagKey":"holdout-sdk-ci-dependencies-test-force-holdout","flagVersion":2,"parentDependencies":null,"type":"holdout-group","variants":[{"key":"holdout","payload":{"flagIds":[]}},{"key":"on","payload":{"flagIds":["44564"]}}],"variantsInclusions":{}},{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"control":1,"treatment":0}}],"bucketingGroupType":null,"bucketingKey":"device_id","conditions":[],"name":"All Other Users"},"bucketingGroupType":null,"bucketingSalt":"OI9rGc1K","customSegmentTargetingConfigs":[],"defaultValue":"off","deployed":true,"enabled":true,"experimentKey":"exp-1","flagKey":"sdk-ci-local-dependencies-test-holdout","flagVersion":5,"parentDependencies":{"flags":{"holdout-sdk-ci-dependencies-test-force-holdout":["on"]},"operator":"ALL"},"type":"experiment","variants":[{"key":"control","payload":null},{"key":"treatment","payload":null}],"variantsInclusions":{}}]'
      stub_request(:get, 'https://api.lab.amplitude.com/sdk/v1/flags')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => "Api-Key #{SERVER_API_KEY}",
            'Content-Type' => 'application/json;charset=utf-8',
            'X-Amp-Exp-Library' => "experiment-ruby-server/#{VERSION}",
            'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: response, headers: {})
    end

    describe '#initialize' do
      it 'error if api_key is nil' do
        expect { LocalEvaluationClient.new(nil) }.to raise_error(ArgumentError)
      end

      it 'error if api_key is empty' do
        expect { LocalEvaluationClient.new('') }.to raise_error(ArgumentError)
      end
    end

    describe '#evaluation' do
      it 'evaluation should return specific variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(TEST_USER, ['sdk-local-evaluation-ci-test'])
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new('on', 'payload'))
      end

      it 'evaluation should return all variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(TEST_USER)
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new('on', 'payload'))
      end

      it 'evaluation with dependencies should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(TEST_USER_2)
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new('control', nil))
      end

      it 'evaluation with dependencies and flag keys should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(TEST_USER_2, ['sdk-ci-local-dependencies-test'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new('control', nil))
      end

      it 'evaluation with dependencies and flag keys not existing should not return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(TEST_USER_2, ['does-not-exist'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new('control', nil))
      end

      it 'evaluation with dependencies holdout excludes variant from expeirment' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(TEST_USER_2)
        expect(result['sdk-ci-local-dependencies-test-holdout']).to eq(nil)
      end

      # TODO: remove after PR review
      # it 'test evaluation with assignment config' do
      #   amp_config = AmplitudeAnalytics::Config.new
      #   assignment_config = AssignmentConfig.new('a6dd847b9d2f03c816d4f3f8458cdc1d', amp_config: amp_config)
      #   local_config = LocalEvaluationConfig.new(assignment_config: assignment_config)
      #   client = LocalEvaluationClient.new(SERVER_API_KEY, local_config)
      #   client.start
      #   client.evaluate(User.new(user_id: 'tim.yiu@amplitude.com'))
      #   client.assignment_service.amplitude.flush
      #   sleep(10)
      # end
    end
  end
end
