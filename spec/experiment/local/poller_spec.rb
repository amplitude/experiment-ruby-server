require 'spec_helper'

module AmplitudeExperiment

  describe FlagConfigPoller do
    response = '[{"allUsersTargetingConfig":{"allocations":[{"percentage":10000,"weights":{"on":1}}],"bucketingKey":"device_id","conditions":[],"name":"default-segment"},"bucketingKey":"device_id","bucketingSalt":"52vuIAwB","customSegmentTargetingConfigs":[],"defaultValue":"off","enabled":true,"evalMode":"LOCAL","flagKey":"asdf-1","flagName":"asdf","flagVersion":7,"globalHoldbackBucketingKey":"amplitude_id","globalHoldbackPct":0,"globalHoldbackSalt":null,"mutualExclusionConfig":null,"type":"RELEASE","useStickyBucketing":false,"userProperty":"[Experiment] asdf-1","variants":[{"key":"on","payload":null}],"variantsExclusions":null,"variantsInclusions":{}}]'
    flag_config = {"asdf-1" => {"allUsersTargetingConfig"=>{"allocations"=>[{"percentage"=>10000, "weights"=>{"on"=>1}}], "bucketingKey"=>"device_id", "conditions"=>[], "name"=>"default-segment"}, "bucketingKey"=>"device_id", "bucketingSalt"=>"52vuIAwB", "customSegmentTargetingConfigs"=>[], "defaultValue"=>"off", "enabled"=>true, "evalMode"=>"LOCAL", "flagKey"=>"asdf-1", "flagName"=>"asdf", "flagVersion"=>7, "globalHoldbackBucketingKey"=>"amplitude_id", "globalHoldbackPct"=>0, "globalHoldbackSalt"=>nil, "mutualExclusionConfig"=>nil, "type"=>"RELEASE", "useStickyBucketing"=>false, "userProperty"=>"[Experiment] asdf-1", "variants"=>[{"key"=>"on", "payload"=>nil}], "variantsExclusions"=>nil, "variantsInclusions"=>{}}}

    describe '#start' do
      it 'start the poller should store the flag config correctly in cache ' do
        stub_request(:get, 'https://api.lab.amplitude.com/sdk/rules?eval_mode=local')
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => "Api-Key #{SERVER_API_KEY}",
              'Content-Type' => 'application/json;charset=utf-8',
              'User-Agent' => 'Ruby'
            }
          ).to_return(status: 200, body: response, headers: {})

        cache = InMemoryFlagConfigCache.new
        fetcher = LocalEvaluationFetcher.new(SERVER_API_KEY, false)
        poller = FlagConfigPoller.new(fetcher, cache, false)
        poller.start
        expect(cache.get_all).to eq(flag_config)
      end

      describe '#stop' do
        it 'stop should exit the poller thread' do
          stub_request(:get, 'https://api.lab.amplitude.com/sdk/rules?eval_mode=local')
            .with(
              headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Authorization' => "Api-Key #{SERVER_API_KEY}",
                'Content-Type' => 'application/json;charset=utf-8',
                'User-Agent' => 'Ruby'
              }
            ).to_return(status: 200, body: response, headers: {})

          cache = InMemoryFlagConfigCache.new
          fetcher = LocalEvaluationFetcher.new(SERVER_API_KEY, false)
          poller = FlagConfigPoller.new(fetcher, cache, false)
          poller.stop

          expect(poller.instance_variable_get("@is_running")).to eq(false)
          expect(poller.instance_variable_get("@poller_thread")).to eq(nil)
        end
      end
    end

  end
end
