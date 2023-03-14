require 'spec_helper'
require 'benchmark'

module AmplitudeExperiment
  SERVER_API_KEY = 'server-qz35UwzJ5akieoAdIgzM4m9MIiOLXLoz'.freeze

  describe LocalEvaluationClient do
    local_evaluation_client = nil
    def random_benchmark_flag
      n = rand(4)
      "local-evaluation-benchmark-#{n}"
    end

    def random_boolean
      [true, false].sample
    end

    def random_string(length)
      [*('A'..'Z'), *('a'..'z'), *('0'..'9')].sample(length).join
    end

    def random_experiment_user
      n = 15
      user = User.new(user_id: random_string(n))

      user.device_id = random_string(n) if random_boolean
      user.platform = random_string(n) if random_boolean
      user.version = random_string(n)  if random_boolean
      user.os = random_string(n) if random_boolean
      user.device_manufacturer = random_string(n) if random_boolean
      user.device_model = random_string(n) if random_boolean
      user.device_brand = random_string(n) if random_boolean
      user.user_properties = { test: 'test' } if random_boolean
      user
    end

    before(:each) do
      local_evaluation_client = LocalEvaluationClient.new(SERVER_API_KEY)
      response = '[{"allUsersTargetingConfig":{"allocations":[{"percentage":0,"weights":{"array-payload":0,"control":0,"object-payload":0}}],"bucketingKey":"device_id","conditions":[],"name":"default-segment"},"bucketingKey":"device_id","bucketingSalt":"6jLqNjj5","customSegmentTargetingConfigs":[{"allocations":[{"percentage":9900,"weights":{"array-payload":0,"boolean-payload":0,"control":1,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"user_id","conditions":[{"op":"IS","prop":"gp:bucket","values":["user_id"]}],"name":"Bucket by User ID"},{"allocations":[{"percentage":9900,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":1}}],"bucketingKey":"device_id","conditions":[{"op":"IS","prop":"gp:bucket","values":["device_id"]}],"name":"Bucket by Device ID"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":1,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"IS","prop":"gp:test is","values":["string","true","1312.1"]},{"op":"IS_NOT","prop":"gp:test is not","values":["string","true","1312.1"]}],"name":"Test IS & IS NOT"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":1,"control":0,"null-payload":0,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"CONTAINS","prop":"gp:test contains","values":["@amplitude.com"]},{"op":"DOES_NOT_CONTAIN","prop":"gp:test does not contain","values":["asdf"]}],"name":"Test CONTAINS & DOES_NOT_CONTAIN"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":0,"number-payload":0,"object-payload":1,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"GREATER_THAN","prop":"gp:test greater","values":["1.2.3"]},{"op":"GREATER_THAN_EQUALS","prop":"gp:test greater or equal","values":["1.2.3"]},{"op":"LESS_THAN","prop":"gp:test less","values":["1.2.3"]},{"op":"LESS_THAN_EQUALS","prop":"gp:test less or equal","values":["1.2.3"]}],"name":"Test GREATER & GREATER OR EQUAL & LESS & LESS OR EQUAL"},{"allocations":[{"percentage":10000,"weights":{"array-payload":0,"boolean-payload":0,"control":0,"null-payload":1,"number-payload":0,"object-payload":0,"string-payload":0,"treatment":0}}],"bucketingKey":"device_id","conditions":[{"op":"SET_CONTAINS","prop":"gp:test set contains","values":["asdf"]}],"name":"Test SET_CONTAINS (not supported)"}],"defaultValue":"off","enabled":true,"evalMode":"LOCAL","flagKey":"sdk-local-evaluation-unit-test","flagName":"sdk-local-evaluation-unit-test","flagVersion":33,"globalHoldbackBucketingKey":"amplitude_id","globalHoldbackPct":0,"globalHoldbackSalt":null,"mutualExclusionConfig":null,"type":"RELEASE","useStickyBucketing":false,"userProperty":"[Experiment] sdk-local-evaluation-unit-test","variants":[{"key":"control","payload":null},{"key":"treatment","payload":null},{"key":"string-payload","payload":"string"},{"key":"number-payload","payload":1312.1},{"key":"boolean-payload","payload":true},{"key":"object-payload","payload":{"array":[1,2,3],"boolean":true,"number":2,"object":{"k":"v"},"string":"value"}},{"key":"array-payload","payload":[1,2,3,"4",true,{"k":"v"},[1,2,3]]},{"key":"null-payload","payload":null}],"variantsExclusions":null,"variantsInclusions":{"array-payload":["array-payload"],"boolean-payload":["boolean-payload"],"control":["control"],"null-payload":["null-payload"],"number-payload":["number-payload"],"object-payload":["object-payload"],"string-payload":["string-payload"],"treatment":["treatment"]}}]'

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

      local_evaluation_client.start
      local_evaluation_client.evaluate(random_experiment_user)
    end

    after(:each) do
      local_evaluation_client.stop
    end

    it '1 flag < 10ms' do
      duration = Benchmark.measure do
        user = random_experiment_user
        flag = random_benchmark_flag
        local_evaluation_client.evaluate(user, [flag])
      end
      expect(duration.real < 10)
    end

    it '10 flag < 10ms' do
      total_duration = 0
      10.times do
        duration = Benchmark.measure do
          user = random_experiment_user
          flag = random_benchmark_flag
          local_evaluation_client.evaluate(user, [flag])
        end
        total_duration += duration.real
      end
      expect(total_duration < 10)
    end

    it '100 flags < 100ms' do
      total_duration = 0
      100.times do
        duration = Benchmark.measure do
          user = random_experiment_user
          flag = random_benchmark_flag
          local_evaluation_client.evaluate(user, [flag])
        end
        total_duration += duration.real
      end
      expect(total_duration < 100)
    end

    it '1000 flags < 1000ms' do
      total_duration = 0
      1000.times do
        duration = Benchmark.measure do
          user = random_experiment_user
          flag = random_benchmark_flag
          local_evaluation_client.evaluate(user, [flag])
        end
        total_duration += duration.real
      end
      expect(total_duration < 1000)
    end
  end
end
