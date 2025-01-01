require 'dotenv'
module AmplitudeExperiment
  describe LocalEvaluationClient do
    Dotenv.load
    let(:api_key) { 'server-qz35UwzJ5akieoAdIgzM4m9MIiOLXLoz' }
    let(:api_key_eu) { 'server-Qlp7XiSu6JtP2S3JzA95PnP27duZgQCF' }
    cohort_sync_config = CohortSyncConfig.new(
      ENV['API_KEY'],
      ENV['SECRET_KEY']
    )
    cohort_sync_config_eu = CohortSyncConfig.new(
      ENV['EU_API_KEY'],
      ENV['EU_SECRET_KEY']
    )
    let(:config) { LocalEvaluationConfig.new(cohort_sync_config: cohort_sync_config) }
    let(:config_eu) { LocalEvaluationConfig.new(cohort_sync_config: cohort_sync_config_eu, server_zone: ServerZone::EU) }

    describe '#evaluate with cohorts' do
      it 'evaluates targeted and non-targeted users' do
        client = LocalEvaluationClient.new(api_key, config)
        client.start

        targeted_user = User.new(user_id: '12345', device_id: 'device')
        targeted_result = client.evaluate_v2(targeted_user, ['sdk-local-evaluation-user-cohort-ci-test'])
        expect(targeted_result['sdk-local-evaluation-user-cohort-ci-test']).to eq(Variant.new(key: 'on', value: 'on'))

        non_targeted_user = User.new(user_id: 'not_targeted')
        non_targeted_result = client.evaluate_v2(non_targeted_user, ['sdk-local-evaluation-user-cohort-ci-test'])
        expect(non_targeted_result['sdk-local-evaluation-user-cohort-ci-test']).to eq(Variant.new(key: 'off'))
      end

      it 'evaluates targeted and non-targeted group cohorts' do
        client = LocalEvaluationClient.new(api_key, config)
        client.start

        targeted_user = User.new(user_id: '12345', device_id: 'device', groups: { 'org id' => ['1'] })
        targeted_result = client.evaluate_v2(targeted_user, ['sdk-local-evaluation-group-cohort-ci-test'])
        expect(targeted_result['sdk-local-evaluation-group-cohort-ci-test']).to eq(Variant.new(key: 'on', value: 'on'))

        non_targeted_user = User.new(user_id: '12345', device_id: 'device', groups: { 'org id' => ['not_targeted'] })
        non_targeted_result = client.evaluate_v2(non_targeted_user, ['sdk-local-evaluation-group-cohort-ci-test'])
        expect(non_targeted_result['sdk-local-evaluation-group-cohort-ci-test']).to eq(Variant.new(key: 'off'))
      end

      it 'logs warning when cohorts are not in storage with sync config' do
        client = LocalEvaluationClient.new(api_key, config)
        client.start

        # Access the private instance variable for cohort_storage
        cohort_storage = client.instance_variable_get(:@cohort_storage)
        allow(cohort_storage).to receive(:put_cohort).and_return(nil)
        allow(cohort_storage).to receive(:cohort_ids).and_return(Set.new)

        # Access the private instance variable for logger
        logger = client.instance_variable_get(:@logger)
        allow(logger).to receive(:warn)

        targeted_user = User.new(user_id: '12345')

        expect(logger).to receive(:warn).with(/Evaluating flag sdk-local-evaluation-user-cohort-ci-test dependent on cohorts .* without .* in storage/)

        client.evaluate_v2(targeted_user, ['sdk-local-evaluation-user-cohort-ci-test'])
      end

      it 'evaluates targeted and non-targeted users in eu' do
        client = LocalEvaluationClient.new(api_key_eu, config_eu)
        client.start

        targeted_user = User.new(user_id: '1', device_id: '0')
        targeted_result = client.evaluate_v2(targeted_user, ['sdk-local-evaluation-user-cohort'])
        expect(targeted_result['sdk-local-evaluation-user-cohort']).to eq(Variant.new(key: 'on', value: 'on'))

        non_targeted_user = User.new(user_id: 'not_targeted')
        non_targeted_result = client.evaluate_v2(non_targeted_user, ['sdk-local-evaluation-user-cohort'])
        expect(non_targeted_result['sdk-local-evaluation-user-cohort']).to eq(Variant.new(key: 'off'))
      end
    end
  end
end
