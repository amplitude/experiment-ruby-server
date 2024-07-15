require 'spec_helper'
require 'experiment/util/flag_config'
require 'set'

module AmplitudeExperiment
  RSpec.describe 'CohortUtils' do
    before(:each) do
      @flags = [
        {
          'key' => 'flag-1',
          'metadata' => {
            'deployed' => true,
            'evaluationMode' => 'local',
            'flagType' => 'release',
            'flagVersion' => 1
          },
          'segments' => [
            {
              'conditions' => [
                [
                  {
                    'op' => 'set contains any',
                    'selector' => %w[context user cohort_ids],
                    'values' => %w[cohort1 cohort2]
                  }
                ]
              ],
              'metadata' => { 'segmentName' => 'Segment A' },
              'variant' => 'on'
            },
            {
              'metadata' => { 'segmentName' => 'All Other Users' },
              'variant' => 'off'
            }
          ],
          'variants' => {
            'off' => {
              'key' => 'off',
              'metadata' => { 'default' => true }
            },
            'on' => {
              'key' => 'on',
              'value' => 'on'
            }
          }
        },
        {
          'key' => 'flag-2',
          'metadata' => {
            'deployed' => true,
            'evaluationMode' => 'local',
            'flagType' => 'release',
            'flagVersion' => 2
          },
          'segments' => [
            {
              'conditions' => [
                [
                  {
                    'op' => 'set contains any',
                    'selector' => %w[context user cohort_ids],
                    'values' => %w[cohort3 cohort4 cohort5 cohort6]
                  }
                ]
              ],
              'metadata' => { 'segmentName' => 'Segment B' },
              'variant' => 'on'
            },
            {
              'metadata' => { 'segmentName' => 'All Other Users' },
              'variant' => 'off'
            }
          ],
          'variants' => {
            'off' => {
              'key' => 'off',
              'metadata' => { 'default' => true }
            },
            'on' => {
              'key' => 'on',
              'value' => 'on'
            }
          }
        },
        {
          'key' => 'flag-3',
          'metadata' => {
            'deployed' => true,
            'evaluationMode' => 'local',
            'flagType' => 'release',
            'flagVersion' => 3
          },
          'segments' => [
            {
              'conditions' => [
                [
                  {
                    'op' => 'set contains any',
                    'selector' => %w[context groups group_name cohort_ids],
                    'values' => %w[cohort7 cohort8]
                  }
                ]
              ],
              'metadata' => { 'segmentName' => 'Segment C' },
              'variant' => 'on'
            },
            {
              'metadata' => { 'segmentName' => 'All Other Groups' },
              'variant' => 'off'
            }
          ],
          'variants' => {
            'off' => {
              'key' => 'off',
              'metadata' => { 'default' => true }
            },
            'on' => {
              'key' => 'on',
              'value' => 'on'
            }
          }
        }
      ]
    end

    describe '#get_all_cohort_ids_from_flag' do
      it 'returns all cohort ids from a single flag' do
        expected_cohort_ids = Set.new(%w[cohort1 cohort2 cohort3 cohort4 cohort5 cohort6 cohort7 cohort8])
        @flags.each do |flag|
          cohort_ids = AmplitudeExperiment.get_all_cohort_ids_from_flag(flag)
          expect(cohort_ids).to be_subset(expected_cohort_ids)
        end
      end
    end

    describe '#get_grouped_cohort_ids_from_flag' do
      it 'returns grouped cohort ids from a single flag' do
        expected_grouped_cohort_ids = {
          'User' => Set.new(%w[cohort1 cohort2 cohort3 cohort4 cohort5 cohort6]),
          'group_name' => Set.new(%w[cohort7 cohort8])
        }
        @flags.each do |flag|
          grouped_cohort_ids = AmplitudeExperiment.get_grouped_cohort_ids_from_flag(flag)
          grouped_cohort_ids.each do |key, values|
            expect(expected_grouped_cohort_ids.keys).to include(key)
            expect(expected_grouped_cohort_ids[key]).to be_superset(values)
          end
        end
      end
    end

    describe '#get_all_cohort_ids_from_flags' do
      it 'returns all cohort ids from multiple flags' do
        expected_cohort_ids = Set.new(%w[cohort1 cohort2 cohort3 cohort4 cohort5 cohort6 cohort7 cohort8])
        cohort_ids = AmplitudeExperiment.get_all_cohort_ids_from_flags(@flags)
        expect(cohort_ids).to eq(expected_cohort_ids)
      end
    end

    describe '#get_grouped_cohort_ids_from_flags' do
      it 'returns grouped cohort ids from multiple flags' do
        expected_grouped_cohort_ids = {
          'User' => Set.new(%w[cohort1 cohort2 cohort3 cohort4 cohort5 cohort6]),
          'group_name' => Set.new(%w[cohort7 cohort8])
        }
        grouped_cohort_ids = AmplitudeExperiment.get_grouped_cohort_ids_from_flags(@flags)
        expect(grouped_cohort_ids).to eq(expected_grouped_cohort_ids)
      end
    end
  end
end
