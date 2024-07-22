require 'benchmark'

module AmplitudeExperiment

  describe LocalEvaluationClient do
    SERVER_API_KEY = 'server-qz35UwzJ5akieoAdIgzM4m9MIiOLXLoz'.freeze
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
      response = '[{"key":"holdout-sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":1},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42520177],"variant":"holdout"},{"range":[42520175,42949673],"variant":"on"}],"range":[0,100]}],"salt":"ubvfZywq","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["44564"]},"value":"on"}}},{"key":"mutex-sdk-ci-local-dependencies-test-mutex","metadata":{"deployed":false,"evaluationMode":"local","flagType":"mutual-exclusion-group","flagVersion":1},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42949673],"variant":"slot-1"}],"range":[0,100]}],"salt":"nI33zio8","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"unallocated":{"key":"unallocated","payload":{"flagIds":[]},"value":"unallocated"},"slot-1":{"key":"slot-1","payload":{"flagIds":["42953"]},"value":"slot-1"},"off":{"key":"off","metadata":{"default":true}}}},{"key":"sdk-ci-local-dependencies-test","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":9},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-local-dependencies-test-holdout","key"],"values":["on"]}],[{"op":"is not","selector":["result","mutex-sdk-ci-local-dependencies-test-mutex","key"],"values":["slot-1"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"sdk-cohort-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":29},"segments":[{"conditions":[[{"op":"IS","selector":["userdata_cohort"],"values":["ursx46e","mg7og2z"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"on":{"key":"on","value":"on"},"off":{"key":"off","metadata":{"default":true}}}},{"key":"sdk-local-evaluation-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":7},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"on"}],"variants":{"on":{"key":"on","value":"on","payload":"payload"},"off":{"key":"off","metadata":{"default":true}}}},{"key":"holdout-sdk-ci-dependencies-test-force-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":2},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42520177],"variant":"holdout"},{"range":[42520175,42949673],"variant":"on"}],"range":[0,100]}],"salt":"ubvfZywq","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["44564"]},"value":"on"}}},{"key":"sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":5},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-dependencies-test-force-holdout","key"],"values":["on"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"local-cohort-target-cacheing","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":5},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["7irdlavw","wv1dk06","57vw40k","ysm884hm"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}}]'

      stub_request(:get, 'https://api.lab.amplitude.com/sdk/v2/flags?v=0')
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
