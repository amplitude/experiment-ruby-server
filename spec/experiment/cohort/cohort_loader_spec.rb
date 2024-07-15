require 'rspec'
module AmplitudeExperiment
  RSpec.describe CohortLoader do
    before(:each) do
      @api = double('CohortDownloadApi')
      @storage = InMemoryCohortStorage.new
      @loader = CohortLoader.new(@api, @storage)
    end

    describe '#load_cohort' do
      it 'loads cohorts successfully' do
        allow(@api).to receive(:get_cohort).with('a').and_return(
          Cohort.new('a', 0, 1, Set.new(['1']))
        )
        allow(@api).to receive(:get_cohort).with('b').and_return(
          Cohort.new('b', 0, 2, Set.new(%w[1 2]))
        )

        future_a = @loader.load_cohort('a')
        future_b = @loader.load_cohort('b')

        future_a.result
        future_b.result

        expect(@storage.get_cohort('a')).to eq(Cohort.new('a', 0, 1, Set.new(['1'])))
        expect(@storage.get_cohort('b')).to eq(Cohort.new('b', 0, 2, Set.new(%w[1 2])))

        expect(@storage.get_cohorts_for_user('1', Set.new(%w[a b]))).to eq(Set.new(%w[a b]))
        expect(@storage.get_cohorts_for_user('2', Set.new(%w[a b]))).to eq(Set.new(['b']))
      end

      it 'filters cohorts already computed' do
        @storage.put_cohort(Cohort.new('a', 0, 0, Set.new))
        @storage.put_cohort(Cohort.new('b', 0, 0, Set.new))

        allow(@api).to receive(:get_cohort).with('a').and_return(
          Cohort.new('a', 0, 0, Set.new)
        )
        allow(@api).to receive(:get_cohort).with('b').and_return(
          Cohort.new('b', 1, 2, Set.new(%w[1 2]))
        )

        @loader.load_cohort('a').result
        @loader.load_cohort('b').result

        expect(@storage.get_cohort('a')).to eq(Cohort.new('a', 0, 0, Set.new))
        expect(@storage.get_cohort('b')).to eq(Cohort.new('b', 1, 2, Set.new(%w[1 2])))

        expect(@storage.get_cohorts_for_user('1', Set.new(%w[a b]))).to eq(Set.new(['b']))
        expect(@storage.get_cohorts_for_user('2', Set.new(%w[a b]))).to eq(Set.new(['b']))
      end

      it 'raises exception on cohort download failure' do
        allow(@api).to receive(:get_cohort).with('a').and_return(
          Cohort.new('a', 0, 1, Set.new(['1']))
        )
        allow(@api).to receive(:get_cohort).with('b').and_raise('Connection timed out')
        allow(@api).to receive(:get_cohort).with('c').and_return(
          Cohort.new('c', 0, 1, Set.new(['1']))
        )

        @loader.load_cohort('a').result

        future_b = @loader.load_cohort('b')
        future_c = @loader.load_cohort('c')

        future_b.on_rejection do |reason|
          expect(reason.message).to eq('Connection timed out')
        end

        # Extract the value from future_c's result triplet
        fulfilled, cohort_c, reason = future_c.result
        expect(cohort_c).to eq(Cohort.new('c', 0, 1, Set.new(['1'])))

        expect(@storage.get_cohorts_for_user('1', Set.new(%w[a b c]))).to eq(Set.new(%w[a c]))
      end

    end
  end
end
