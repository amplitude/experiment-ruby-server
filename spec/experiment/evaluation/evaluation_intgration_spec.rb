# frozen_string_literal: true

require 'net/http'
require 'json'

describe AmplitudeAnalytics::Evaluation::Engine do
  let(:deployment_key) { 'server-NgJxxvg8OGwwBsWVXqyxQbdiflbhvugy' }
  let(:engine) { AmplitudeAnalytics::Evaluation::Engine.new }
  let(:flags) { get_flags(deployment_key) }

  describe 'basic tests' do
    it 'tests off' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-off']
      expect(result.key).to eq('off')
    end

    it 'tests on' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-on']
      expect(result.key).to eq('on')
    end
  end

  describe 'opinionated segment tests' do
    it 'tests individual inclusions match' do
      # Match user ID
      user = user_context('user_id')
      result = engine.evaluate(user, flags)['test-individual-inclusions']
      expect(result.key).to eq('on')
      expect(result.metadata['segmentName']).to eq('individual-inclusions')

      # Match device ID
      user = user_context(nil, 'device_id')
      result = engine.evaluate(user, flags)['test-individual-inclusions']
      expect(result.key).to eq('on')
      expect(result.metadata['segmentName']).to eq('individual-inclusions')

      # Doesn't match user ID
      user = user_context('not_user_id')
      result = engine.evaluate(user, flags)['test-individual-inclusions']
      expect(result.key).to eq('off')

      # Doesn't match device ID
      user = user_context(nil, 'not_device_id')
      result = engine.evaluate(user, flags)['test-individual-inclusions']
      expect(result.key).to eq('off')
    end

    it 'tests flag dependencies on' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-flag-dependencies-on']
      expect(result.key).to eq('on')
    end

    it 'tests flag dependencies off' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-flag-dependencies-off']
      expect(result.key).to eq('off')
      expect(result.metadata['segmentName']).to eq('flag-dependencies')
    end

    it 'tests sticky bucketing' do
      # On
      user = user_context('user_id', 'device_id', nil, {
                            '[Experiment] test-sticky-bucketing' => 'on'
                          })

      result = engine.evaluate(user, flags)['test-sticky-bucketing']
      expect(result.key).to eq('on')
      expect(result.metadata['segmentName']).to eq('sticky-bucketing')

      # Off
      user = user_context('user_id', 'device_id', nil, {
                            '[Experiment] test-sticky-bucketing' => 'off'
                          })
      result = engine.evaluate(user, flags)['test-sticky-bucketing']
      expect(result.key).to eq('off')
      expect(result.metadata['segmentName']).to eq('All Other Users')

      # Non-variant
      user = user_context('user_id', 'device_id', nil, {
                            '[Experiment] test-sticky-bucketing' => 'not-a-variant'
                          })
      result = engine.evaluate(user, flags)['test-sticky-bucketing']
      expect(result.key).to eq('off')
      expect(result.metadata['segmentName']).to eq('All Other Users')
    end
  end

  describe 'experiment and flag segment tests' do
    it 'tests experiment' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-experiment']
      expect(result.key).to eq('on')
      expect(result.metadata['experimentKey']).to eq('exp-1')
    end

    it 'tests flag' do
      user = user_context('user_id', 'device_id')
      result = engine.evaluate(user, flags)['test-flag']
      expect(result.key).to eq('on')
      expect(result.metadata['experimentKey']).to be_nil
    end
  end

  describe 'conditional logic tests' do
    it 'tests multiple conditions and values' do
      # All match
      user = user_context('user_id', 'device_id', nil, {
                            'key-1' => 'value-1',
                            'key-2' => 'value-2',
                            'key-3' => 'value-3'
                          })
      result = engine.evaluate(user, flags)['test-multiple-conditions-and-values']
      expect(result.key).to eq('on')

      # Some match
      user = user_context('user_id', 'device_id', nil, {
                            'key-1' => 'value-1',
                            'key-2' => 'value-2'
                          })
      result = engine.evaluate(user, flags)['test-multiple-conditions-and-values']
      expect(result.key).to eq('off')
    end
  end

  describe 'conditional property targeting tests' do
    it 'tests amplitude property targeting' do
      user = user_context('user_id')
      result = engine.evaluate(user, flags)['test-amplitude-property-targeting']
      expect(result.key).to eq('on')
    end

    it 'tests cohort targeting' do
      user = user_context(nil, nil, nil, nil, %w[u0qtvwla 12345678])
      result = engine.evaluate(user, flags)['test-cohort-targeting']
      expect(result.key).to eq('on')

      user = user_context(nil, nil, nil, nil, %w[12345678 87654321])
      result = engine.evaluate(user, flags)['test-cohort-targeting']
      expect(result.key).to eq('off')
    end

    it 'tests group name targeting' do
      user = group_context('org name', 'amplitude')
      result = engine.evaluate(user, flags)['test-group-name-targeting']
      expect(result.key).to eq('on')
    end

    it 'tests group property targeting' do
      user = group_context('org name', 'amplitude', { 'org plan' => 'enterprise2' })
      result = engine.evaluate(user, flags)['test-group-property-targeting']
      expect(result.key).to eq('on')
    end
  end

  describe 'bucketing tests' do
    it 'tests amplitude id bucketing' do
      user = user_context(nil, nil, '1234567890')
      result = engine.evaluate(user, flags)['test-amplitude-id-bucketing']
      expect(result.key).to eq('on')
    end

    it 'tests user id bucketing' do
      user = user_context('user_id')
      result = engine.evaluate(user, flags)['test-user-id-bucketing']
      expect(result.key).to eq('on')
    end

    it 'tests device id bucketing' do
      user = user_context(nil, 'device_id')
      result = engine.evaluate(user, flags)['test-device-id-bucketing']
      expect(result.key).to eq('on')
    end

    it 'tests custom user property bucketing' do
      user = user_context(nil, nil, nil, { 'key' => 'value' })
      result = engine.evaluate(user, flags)['test-custom-user-property-bucketing']
      expect(result.key).to eq('on')
    end

    it 'tests group name bucketing' do
      user = group_context('org name', 'amplitude')
      result = engine.evaluate(user, flags)['test-group-name-bucketing']
      expect(result.key).to eq('on')
    end

    it 'tests group property bucketing' do
      user = group_context('org name', 'amplitude', { 'org plan' => 'enterprise2' })
      result = engine.evaluate(user, flags)['test-group-name-bucketing']
      expect(result.key).to eq('on')
    end
  end

  describe 'bucketing allocation tests' do
    it 'tests 1 percent allocation' do
      on_count = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-1-percent-allocation']
        on_count += 1 if result&.key == 'on'
      end
      expect(on_count).to eq(107)
    end

    it 'tests 50 percent allocation' do
      on_count = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-50-percent-allocation']
        on_count += 1 if result&.key == 'on'
      end
      expect(on_count).to eq(5009)
    end

    it 'tests 99 percent allocation' do
      on_count = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-99-percent-allocation']
        on_count += 1 if result&.key == 'on'
      end
      expect(on_count).to eq(9900)
    end
  end

  describe 'bucketing distribution tests' do
    it 'tests 1 percent distribution' do
      control = 0
      treatment = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-1-percent-distribution']
        case result&.key
        when 'control'
          control += 1
        when 'treatment'
          treatment += 1
        end
      end
      expect(control).to eq(106)
      expect(treatment).to eq(9894)
    end

    it 'tests 50 percent distribution' do
      control = 0
      treatment = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-50-percent-distribution']
        case result&.key
        when 'control'
          control += 1
        when 'treatment'
          treatment += 1
        end
      end
      expect(control).to eq(4990)
      expect(treatment).to eq(5010)
    end

    it 'tests 99 percent distribution' do
      control = 0
      treatment = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-99-percent-distribution']
        case result&.key
        when 'control'
          control += 1
        when 'treatment'
          treatment += 1
        end
      end
      expect(control).to eq(9909)
      expect(treatment).to eq(91)
    end

    it 'tests multiple distributions' do
      a = 0
      b = 0
      c = 0
      d = 0
      10_000.times do |i|
        user = user_context(nil, (i + 1).to_s)
        result = engine.evaluate(user, flags)['test-multiple-distributions']
        case result&.key
        when 'a' then a += 1
        when 'b' then b += 1
        when 'c' then c += 1
        when 'd' then d += 1
        end
      end
      expect(a).to eq(2444)
      expect(b).to eq(2634)
      expect(c).to eq(2447)
      expect(d).to eq(2475)
    end
  end

  describe 'operator tests' do
    it 'tests is' do
      user = user_context(nil, nil, nil, { 'key' => 'value' })
      result = engine.evaluate(user, flags)['test-is']
      expect(result.key).to eq('on')
    end

    it 'tests is not' do
      user = user_context(nil, nil, nil, { 'key' => 'value' })
      result = engine.evaluate(user, flags)['test-is-not']
      expect(result.key).to eq('on')
    end

    it 'tests contains' do
      user = user_context(nil, nil, nil, { 'key' => 'value' })
      result = engine.evaluate(user, flags)['test-contains']
      expect(result.key).to eq('on')
    end

    it 'tests does not contain' do
      user = user_context(nil, nil, nil, { 'key' => 'value' })
      result = engine.evaluate(user, flags)['test-does-not-contain']
      expect(result.key).to eq('on')
    end

    it 'tests less' do
      user = user_context(nil, nil, nil, { 'key' => '-1' })
      result = engine.evaluate(user, flags)['test-less']
      expect(result.key).to eq('on')
    end

    it 'tests less or equal' do
      user = user_context(nil, nil, nil, { 'key' => '0' })
      result = engine.evaluate(user, flags.select { |f| f.key == 'test-less-or-equal' })['test-less-or-equal']
      expect(result.key).to eq('on')
    end

    it 'tests greater' do
      user = user_context(nil, nil, nil, { 'key' => '1' })
      result = engine.evaluate(user, flags)['test-greater']
      expect(result.key).to eq('on')
    end

    it 'tests greater or equal' do
      user = user_context(nil, nil, nil, { 'key' => '0' })
      result = engine.evaluate(user, flags)['test-greater-or-equal']
      expect(result.key).to eq('on')
    end

    it 'tests version less' do
      user = freeform_user_context({ 'version' => '1.9.0' })
      result = engine.evaluate(user, flags)['test-version-less']
      expect(result.key).to eq('on')
    end

    it 'tests version less or equal' do
      user = freeform_user_context({ 'version' => '1.10.0' })
      result = engine.evaluate(user, flags)['test-version-less-or-equal']
      expect(result.key).to eq('on')
    end

    it 'tests version greater' do
      user = freeform_user_context({ 'version' => '1.10.0' })
      result = engine.evaluate(user, flags)['test-version-greater']
      expect(result.key).to eq('on')
    end

    it 'tests version greater or equal' do
      user = freeform_user_context({ 'version' => '1.9.0' })
      result = engine.evaluate(user, flags)['test-version-greater-or-equal']
      expect(result.key).to eq('on')
    end

    it 'tests set is' do
      user = user_context(nil, nil, nil, { 'key' => %w[1 2 3] })
      result = engine.evaluate(user, flags)['test-set-is']
      expect(result.key).to eq('on')
    end

    it 'tests set is not' do
      user = user_context(nil, nil, nil, { 'key' => %w[1 2] })
      result = engine.evaluate(user, flags)['test-set-is-not']
      expect(result.key).to eq('on')
    end

    it 'tests set contains' do
      user = user_context(nil, nil, nil, { 'key' => %w[1 2 3 4] })
      result = engine.evaluate(user, flags)['test-set-contains']
      expect(result.key).to eq('on')
    end

    it 'tests set does not contain' do
      user = user_context(nil, nil, nil, { 'key' => %w[1 2 4] })
      result = engine.evaluate(user, flags)['test-set-does-not-contain']
      expect(result.key).to eq('on')
    end

    it 'tests set contains any' do
      user = user_context(nil, nil, nil, nil, %w[u0qtvwla 12345678])
      result = engine.evaluate(user, flags)['test-set-contains-any']
      expect(result.key).to eq('on')
    end

    it 'tests set does not contain any' do
      user = user_context(nil, nil, nil, nil, %w[12345678 87654321])
      result = engine.evaluate(user, flags)['test-set-does-not-contain-any']
      expect(result.key).to eq('on')
    end

    it 'tests glob match' do
      user = user_context(nil, nil, nil, { 'key' => '/path/1/2/3/end' })
      result = engine.evaluate(user, flags)['test-glob-match']
      expect(result.key).to eq('on')
    end

    it 'tests glob does not match' do
      user = user_context(nil, nil, nil, { 'key' => '/path/1/2/3' })
      result = engine.evaluate(user, flags)['test-glob-does-not-match']
      expect(result.key).to eq('on')
    end

    it 'tests is with booleans' do
      # Test with uppercase TRUE/FALSE
      user = user_context(nil, nil, nil, {
                            'true' => 'TRUE',
                            'false' => 'FALSE'
                          })
      result = engine.evaluate(user, flags)['test-is-with-booleans']
      expect(result.key).to eq('on')

      # Test with title case True/False
      user = user_context(nil, nil, nil, {
                            'true' => 'True',
                            'false' => 'False'
                          })
      result = engine.evaluate(user, flags)['test-is-with-booleans']
      expect(result.key).to eq('on')

      # Test with lowercase true/false
      user = user_context(nil, nil, nil, {
                            'true' => 'true',
                            'false' => 'false'
                          })
      result = engine.evaluate(user, flags)['test-is-with-booleans']
      expect(result.key).to eq('on')
    end
  end

  # Helper methods
  def user_context(user_id = nil, device_id = nil, amplitude_id = nil, user_properties = nil, cohort_ids = nil)
    {
      'user' => {
        'user_id' => user_id,
        'device_id' => device_id,
        'amplitude_id' => amplitude_id,
        'user_properties' => user_properties,
        'cohort_ids' => cohort_ids
      }
    }
  end

  def freeform_user_context(user)
    {
      'user' => user
    }
  end

  def group_context(group_type, group_name, group_properties = nil)
    {
      'groups' => {
        group_type => {
          'group_name' => group_name,
          'group_properties' => group_properties
        }
      }
    }
  end

  def get_flags(deployment_key)
    server_url = 'https://api.lab.amplitude.com'
    uri = URI("#{server_url}/sdk/v2/flags?eval_mode=remote")

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Api-Key #{deployment_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    raise "Response error #{response.code}" unless response.code == '200'

    JSON.parse(response.body).map { |flag| AmplitudeAnalytics::Evaluation::Flag.from_hash(flag) }
  end
end
