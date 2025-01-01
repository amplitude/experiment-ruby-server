require_relative '../spec_helper'

module AmplitudeAnalytics
  describe Config do
    let(:api_key) { 'test_api_key' }

    it 'initializes with default values successfully' do
      config = Config.new
      expect(config.api_key).to be_nil
      expect(config.flush_queue_size).to eq(FLUSH_QUEUE_SIZE)
      expect(config.flush_interval_millis).to eq(FLUSH_INTERVAL_MILLIS)
      expect(config.flush_max_retries).to eq(FLUSH_MAX_RETRIES)
      # expect(config.logger).to eq(Logger.new(LOGGER_NAME))
      expect(config.min_id_length).to be_nil
      expect(config.server_zone).to eq(DEFAULT_ZONE)
      expect(config.use_batch).to be_falsey
      expect(config.server_url).to eq(SERVER_URL[DEFAULT_ZONE][HTTP_V2])
      expect(config.callback).to be_nil
      expect(config.storage_provider).to be_a(InMemoryStorageProvider)
      expect(config.opt_out).to be_falsey
    end

    it 'checks if none API key is invalid' do
      config = Config.new
      expect(config.valid?).to be_falsey
    end

    it 'sets API key and checks for validity' do
      config = Config.new(api_key: 'test_api_key')
      expect(config.valid?).to be_truthy

      config.api_key = 'test_api_key2'
      expect(config.valid?).to be_truthy
    end

    it 'gets storage provider' do
      config = Config.new
      storage = config.storage
      expect(storage).to be_a(InMemoryStorage)
    end

    it 'checks if min_id_length is valid' do
      config = Config.new
      expect(config.min_id_length_valid?).to be_truthy

      config.min_id_length = 3
      expect(config.min_id_length_valid?).to be_truthy
    end

    it 'checks invalid min_id_length values' do
      config = Config.new(min_id_length: 0)
      expect(config.min_id_length_valid?).to be_falsey
      expect(config.valid?).to be_falsey

      config.min_id_length = 5.4
      expect(config.min_id_length_valid?).to be_falsey
      expect(config.valid?).to be_falsey

      config.min_id_length = '5'
      expect(config.min_id_length_valid?).to be_falsey
      expect(config.valid?).to be_falsey

      config.min_id_length = -4
      expect(config.min_id_length_valid?).to be_falsey
      expect(config.valid?).to be_falsey
    end

    it 'checks options with no min_id_length' do
      config = Config.new
      expect(config.options).to be_nil
    end

    it 'checks options with valid min_id_length' do
      config = Config.new(min_id_length: 7)
      expect(config.options).to eq({ 'min_id_length' => 7 })
    end

    it 'checks server_url with server_zone and use_batch' do
      config = Config.new
      config.use_batch = false
      config.server_zone = DEFAULT_ZONE
      expect(config.server_url).to eq(SERVER_URL[DEFAULT_ZONE][HTTP_V2])

      config.server_zone = EU_ZONE
      expect(config.server_url).to eq(SERVER_URL[EU_ZONE][HTTP_V2])

      config.use_batch = true
      config.server_zone = DEFAULT_ZONE
      expect(config.server_url).to eq(SERVER_URL[DEFAULT_ZONE][BATCH])

      config.server_zone = EU_ZONE
      expect(config.server_url).to eq(SERVER_URL[EU_ZONE][BATCH])
    end

    it 'customizes server_url' do
      config = Config.new
      url = 'http://test_url'
      config.server_url = url
      config.use_batch = false
      config.server_zone = DEFAULT_ZONE
      expect(config.server_url).to eq(url)

      config.server_zone = EU_ZONE
      expect(config.server_url).to eq(url)

      config.use_batch = true
      config.server_zone = DEFAULT_ZONE
      expect(config.server_url).to eq(url)

      config.server_zone = EU_ZONE
      expect(config.server_url).to eq(url)
    end

    it 'modifies flush_queue_size and resets' do
      config = Config.new(flush_queue_size: 30)
      expect(config.flush_queue_size).to eq(30)
      config.increase_flush_divider
      expect(config.flush_queue_size).to eq(15)
      config.increase_flush_divider
      expect(config.flush_queue_size).to eq(10)
      config.reset_flush_divider
      expect(config.flush_queue_size).to eq(30)
    end

    it 'sets flush_queue_size value' do
      config = Config.new(flush_queue_size: 20)
      expect(config.flush_queue_size).to eq(20)
      config.increase_flush_divider
      expect(config.flush_queue_size).to eq(10)
      config.flush_queue_size = 50
      expect(config.flush_queue_size).to eq(50)
      config.increase_flush_divider
    end
  end
end
