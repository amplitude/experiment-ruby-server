require 'spec_helper'
require_relative '../../../lib/amplitude'

module AmplitudeExperiment
  describe LocalEvaluationClient do
    let(:api_key) { 'client-DvWljIjiiuqLbyjqdvBaLFfEBrAvGuA3' }
    let(:test_user) { User.new(user_id: 'test_user') }
    let(:test_user2) { User.new(user_id: 'user_id', device_id: 'device_id') }

    def setup_stub
      response = '[{"key":"sdk-cohort-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":46},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["930zyfa","vcb27be"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}},{"key":"sdk-local-evaluation-user-cohort-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":9},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["52gz3yi7"]}]],"metadata":{"segmentName":"individual-inclusions"},"variant":"on"},{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["mv7fn2bp"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}},{"key":"sdk-ci-test","metadata":{"deployed":true,"evaluationMode":"remote","flagType":"release","flagVersion":30},"segments":[{"metadata":{"segmentName":"default"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":"payload","value":"on"}}},{"key":"evaluation-proxy-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":5},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}},{"key":"split-url-test","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":4},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,429497],"variant":"control"},{"range":[429496,42949673],"variant":"treatment"}],"range":[0,100]}],"salt":"r1wFYK2v","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"test-sandeep-local-eval-cohorts","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":18},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["9p6iyhq6"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"holdout-sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":1},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,429497],"variant":"holdout"},{"range":[429496,42949673],"variant":"on"}],"range":[0,100]}],"salt":"nI33zio8","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["42953"]},"value":"on"}}},{"key":"mutex-sdk-ci-local-dependencies-test-mutex","metadata":{"deployed":false,"evaluationMode":"local","flagType":"mutual-exclusion-group","flagVersion":1},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"slot-1"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"slot-1":{"key":"slot-1","payload":{"flagIds":["42953"]},"value":"slot-1"},"unallocated":{"key":"unallocated","payload":{"flagIds":[]},"value":"unallocated"}}},{"dependencies":["holdout-sdk-ci-local-dependencies-test-holdout","mutex-sdk-ci-local-dependencies-test-mutex"],"key":"sdk-ci-local-dependencies-test","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":9},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-local-dependencies-test-holdout","key"],"values":["on"]}],[{"op":"is not","selector":["result","mutex-sdk-ci-local-dependencies-test-mutex","key"],"values":["slot-1"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"sdk-ci-local-test-instrumentation-test","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":3},"segments":[{"conditions":[[{"op":"is","selector":["context","user","user_id"],"values":["control"]}],[{"op":"is","selector":["context","user","device_id"],"values":["control"]}]],"metadata":{"segmentName":"individual-inclusions"},"variant":"control"},{"conditions":[[{"op":"is","selector":["context","user","user_id"],"values":["treatment"]}],[{"op":"is","selector":["context","user","device_id"],"values":["treatment"]}]],"metadata":{"segmentName":"individual-inclusions"},"variant":"treatment"},{"metadata":{"segmentName":"default"},"variant":"off"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"sdk-local-evaluation-group-cohort-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":14},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["s4t57y32"]}],[{"op":"set contains any","selector":["context","groups","org name","cohort_ids"],"values":["s4t57y32"]}]],"metadata":{"segmentName":"individual-inclusions"},"variant":"on"},{"conditions":[[{"op":"set contains any","selector":["context","groups","org id","cohort_ids"],"values":["k1lklnnb"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}},{"key":"sdk-local-evaluation-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":7},"segments":[{"metadata":{"segmentName":"All Other Users"},"variant":"on"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":"payload","value":"on"}}},{"key":"sdk-payload-ci-test","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":7},"segments":[{"conditions":[[{"op":"is not","selector":["context","user","user_id"],"values":["(none)"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"jsonobject"},{"metadata":{"segmentName":"All Other Users"},"variant":"jsonarray"}],"variants":{"jsonarray":{"key":"jsonarray","payload":[{"key1":"obj1"},{"key2":"obj2"}],"value":"jsonarray"},"jsonobject":{"key":"jsonobject","payload":{"key1":"val1","key2":"val2"},"value":"jsonobject"},"off":{"key":"off","metadata":{"default":true}}}},{"key":"sdk-ci-test-local","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":4},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42949673],"variant":"on"}],"range":[0,99]}],"salt":"pHOipLW7","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}},{"key":"holdout-sdk-ci-dependencies-test-force-holdout","metadata":{"deployed":false,"evaluationMode":"local","flagType":"holdout-group","flagVersion":2},"segments":[{"bucket":{"allocations":[{"distributions":[{"range":[0,42520177],"variant":"holdout"},{"range":[42520175,42949673],"variant":"on"}],"range":[0,100]}],"salt":"ubvfZywq","selector":["context","user","device_id"]},"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"holdout":{"key":"holdout","payload":{"flagIds":[]},"value":"holdout"},"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","payload":{"flagIds":["44564"]},"value":"on"}}},{"dependencies":["holdout-sdk-ci-dependencies-test-force-holdout"],"key":"sdk-ci-local-dependencies-test-holdout","metadata":{"deployed":true,"evaluationMode":"local","experimentKey":"exp-1","flagType":"experiment","flagVersion":5},"segments":[{"conditions":[[{"op":"is not","selector":["result","holdout-sdk-ci-dependencies-test-force-holdout","key"],"values":["on"]}]],"metadata":{"segmentName":"flag-dependencies"},"variant":"off"},{"metadata":{"segmentName":"All Other Users"},"variant":"control"}],"variants":{"control":{"key":"control","value":"control"},"off":{"key":"off","metadata":{"default":true}},"treatment":{"key":"treatment","value":"treatment"}}},{"key":"local-cohort-target-cacheing","metadata":{"deployed":true,"evaluationMode":"local","flagType":"release","flagVersion":5},"segments":[{"conditions":[[{"op":"set contains any","selector":["context","user","cohort_ids"],"values":["7irdlavw","wv1dk06","57vw40k","ysm884hm"]}]],"metadata":{"segmentName":"Segment 1"},"variant":"on"},{"metadata":{"segmentName":"All Other Users"},"variant":"off"}],"variants":{"off":{"key":"off","metadata":{"default":true}},"on":{"key":"on","value":"on"}}}]'
      stub_request(:get, 'https://api.lab.amplitude.com/sdk/v2/flags?v=0')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => "Api-Key #{api_key}",
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

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(test_user, ['sdk-local-evaluation-ci-test'])
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new(key: 'on', value: 'on', payload: 'payload'))
      end

      it 'evaluation should return all variants' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start

        result = local_evaluation_client.evaluate(test_user)
        expect(result['sdk-local-evaluation-ci-test']).to eq(Variant.new(key: 'on', value: 'on', payload: 'payload'))
      end

      it 'evaluation with dependencies should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2)
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new(key: 'control', value: 'control'))
      end

      it 'evaluation with dependencies and flag keys should return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2, ['sdk-ci-local-dependencies-test'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(Variant.new(key: 'control', value: 'control'))
      end

      it 'evaluation with dependencies and flag keys not existing should not return variant' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2, ['does-not-exist'])
        expect(result['sdk-ci-local-dependencies-test']).to eq(nil)
      end

      it 'evaluation with dependencies holdout excludes variant from experiment' do
        setup_stub

        local_evaluation_client = LocalEvaluationClient.new(api_key)
        local_evaluation_client.start
        result = local_evaluation_client.evaluate(test_user2)
        expect(result['sdk-ci-local-dependencies-test-holdout']).to eq(nil)
      end
    end
  end
end
