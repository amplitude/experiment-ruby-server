require 'rspec'
module AmplitudeExperiment
  describe DeploymentRunner do
    let(:cohort_id) { '1234' }
    before(:each) do
      @flag = {
        'key' => 'flag',
        'variants' => {},
        'segments' => [
          {
            'conditions' => [
              [
                {
                  'selector' => %w[context user cohort_ids],
                  'op' => 'set contains any',
                  'values' => [cohort_id]
                }
              ]
            ]
          }
        ]
      }
    end

    describe '#start' do
      it 'throws an error if the first flag config load fails' do
        flag_fetcher = double('LocalEvaluationFetcher')
        cohort_download_api = double('CohortLoader')
        flag_config_storage = double('FlagConfigStorage')
        cohort_storage = double('CohortStorage')
        cohort_loader = CohortLoader.new(cohort_download_api, cohort_storage)
        logger = Logger.new($stdout)
        runner = DeploymentRunner.new(
          LocalEvaluationConfig.new(),
          flag_fetcher,
          flag_config_storage,
          cohort_storage,
          logger,
          cohort_loader
        )

        allow(flag_fetcher).to receive(:fetch_v2).and_raise(RuntimeError, 'test')

        expect { runner.start }.to raise_error(RuntimeError, 'test')
      end

      it 'does not raise an error if the first cohort load fails' do
        flag_fetcher = double('LocalEvaluationFetcher')
        cohort_download_api = double('CohortLoader')
        flag_config_storage = double('FlagConfigStorage')
        cohort_storage = double('CohortStorage')
        cohort_loader = CohortLoader.new(cohort_download_api, cohort_storage)
        logger = Logger.new($stdout)
        runner = DeploymentRunner.new(
          LocalEvaluationConfig.new(),
          flag_fetcher,
          flag_config_storage,
          cohort_storage,
          logger,
          cohort_loader
        )

        allow(flag_fetcher).to receive(:fetch_v2).and_return([@flag])
        allow(flag_config_storage).to receive(:remove_if).and_return(nil)
        allow(flag_config_storage).to receive(:flag_configs).and_return({})
        allow(flag_config_storage).to receive(:put_flag_config).and_return(nil)
        allow(cohort_storage).to receive(:cohort_ids).and_return(Set.new)
        allow(cohort_storage).to receive(:cohorts).and_return({})
        allow(cohort_storage).to receive(:cohort).and_return(nil)
        allow(cohort_download_api).to receive(:get_cohort).and_raise(RuntimeError, 'test')

        # Expect no error to be raised
        expect { runner.start }.not_to raise_error
      end
    end
  end
end
