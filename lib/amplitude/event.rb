require 'json'

module AmplitudeAnalytics
  # Plan
  class Plan
    PLAN_KEY_MAPPING = {
      'branch' => ['branch', String],
      'source' => ['source', String],
      'version' => ['version', String],
      'version_id' => ['versionId', String]
    }.freeze

    attr_accessor :branch, :source, :version, :version_id

    def initialize(branch: nil, source: nil, version: nil, version_id: nil)
      @branch = branch
      @source = source
      @version = version
      @version_id = version_id
    end

    def plan_body
      result = {}
      PLAN_KEY_MAPPING.each do |key, mapping|
        next unless instance_variable_defined?("@#{key}") && !instance_variable_get("@#{key}").nil?

        value = instance_variable_get("@#{key}")
        if value.is_a?(mapping[1])
          result[mapping[0]] = value
        else
          puts "#{self.class}.#{key} expected #{mapping[1]} but received #{value.class}."
        end
      end
      result
    end
  end

  # IngestionMetadata
  class IngestionMetadata
    INGESTION_METADATA_KEY_MAPPING = {
      'source_name' => ['source_name', String],
      'source_version' => ['source_version', String]
    }.freeze

    attr_accessor :source_name, :source_version

    def initialize(source_name: nil, source_version: nil)
      @source_name = source_name
      @source_version = source_version
    end

    def body
      result = {}
      INGESTION_METADATA_KEY_MAPPING.each do |key, mapping|
        next unless instance_variable_defined?("@#{key}") && !instance_variable_get("@#{key}").nil?

        value = instance_variable_get("@#{key}")
        if value.is_a?(mapping[1])
          result[mapping[0]] = value
        else
          puts "#{self.class}.#{key} expected #{mapping[1]} but received #{value.class}."
        end
      end
      result
    end
  end

  # EventOptions
  class EventOptions
    EVENT_KEY_MAPPING = {
      'user_id' => ['user_id', String],
      'device_id' => ['device_id', String],
      'event_type' => ['event_type', String],
      'time' => ['time', Integer],
      'event_properties' => ['event_properties', Hash],
      'user_properties' => ['user_properties', Hash],
      'groups' => ['groups', Hash],
      'app_version' => ['app_version', String],
      'platform' => ['platform', String],
      'os_name' => ['os_name', String],
      'os_version' => ['os_version', String],
      'device_brand' => ['device_brand', String],
      'device_manufacturer' => ['device_manufacturer', String],
      'device_model' => ['device_model', String],
      'carrier' => ['carrier', String],
      'country' => ['country', String],
      'region' => ['region', String],
      'city' => ['city', String],
      'dma' => ['dma', String],
      'language' => ['language', String],
      'price' => ['price', Float],
      'quantity' => ['quantity', Integer],
      'revenue' => ['revenue', Float],
      'product_id' => ['productId', String],
      'revenue_type' => ['revenueType', String],
      'location_lat' => ['location_lat', Float],
      'location_lng' => ['location_lng', Float],
      'ip' => ['ip', String],
      'idfa' => ['idfa', String],
      'idfv' => ['idfv', String],
      'adid' => ['adid', String],
      'android_id' => ['android_id', String],
      'event_id' => ['event_id', Integer],
      'session_id' => ['session_id', Integer],
      'insert_id' => ['insert_id', String],
      'library' => ['library', String],
      'plan' => ['plan', Plan],
      'ingestion_metadata' => ['ingestion_metadata', IngestionMetadata],
      'group_properties' => ['group_properties', Hash],
      'partner_id' => ['partner_id', String],
      'version_name' => ['version_name', String]
    }.freeze

    attr_accessor :user_id, :device_id, :event_type, :time, :event_properties, :user_properties,
                  :groups, :app_version, :platform, :os_name, :os_version, :device_brand,
                  :device_manufacturer, :device_model, :carrier, :country, :region, :city,
                  :dma, :language, :price, :quantity, :revenue, :product_id, :revenue_type,
                  :location_lat, :location_lng, :ip, :idfa, :idfv, :adid, :android_id,
                  :event_id, :session_id, :insert_id, :library, :plan, :ingestion_metadata,
                  :group_properties, :partner_id, :version_name, :retry

    def initialize(event_type, user_id: nil, device_id: nil, time: nil, event_properties: nil,
                   user_properties: nil, groups: nil, app_version: nil, platform: nil, os_name: nil,
                   os_version: nil, device_brand: nil, device_manufacturer: nil, device_model: nil,
                   carrier: nil, country: nil, region: nil, city: nil, dma: nil, language: nil,
                   price: nil, quantity: nil, revenue: nil, product_id: nil, revenue_type: nil,
                   location_lat: nil, location_lng: nil, ip: nil, idfa: nil, idfv: nil, adid: nil,
                   android_id: nil, event_id: nil, session_id: nil, insert_id: nil, plan: nil,
                   ingestion_metadata: nil, group_properties: nil, partner_id: nil, version_name: nil,
                   callback: nil)
      @user_id = user_id
      @device_id = device_id
      @event_type = event_type
      @time = time
      @event_properties = event_properties
      @user_properties = user_properties
      @groups = groups
      @app_version = app_version
      @platform = platform
      @os_name = os_name
      @os_version = os_version
      @device_brand = device_brand
      @device_manufacturer = device_manufacturer
      @device_model = device_model
      @carrier = carrier
      @country = country
      @region = region
      @city = city
      @dma = dma
      @language = language
      @price = price
      @quantity = quantity
      @revenue = revenue
      @product_id = product_id
      @revenue_type = revenue_type
      @location_lat = location_lat
      @location_lng = location_lng
      @ip = ip
      @idfa = idfa
      @idfv = idfv
      @adid = adid
      @android_id = android_id
      @event_id = event_id
      @session_id = session_id
      @insert_id = insert_id
      @plan = plan
      @ingestion_metadata = ingestion_metadata
      @group_properties = group_properties
      @partner_id = partner_id
      @version_name = version_name
      @event_callback = callback
      @retry = 0
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def []=(key, value)
      send("#{key}=", value) if respond_to?("#{key}=")
    end

    def include?(key)
      instance_variable_defined?("@#{key}") && !instance_variable_get("@#{key}").nil?
    end

    def event_body
      event_body = {}
      EVENT_KEY_MAPPING.each do |key, mapping|
        next unless include?(key) && self[key]

        value = self[key]
        if value.is_a?(mapping[1])
          event_body[mapping[0]] = value
        else
          puts "#{self.class}.#{key} expected #{mapping[1]} but received #{value.class}."
        end
      end
      event_body['plan'] = @plan.plan_body if @plan.respond_to?(:plan_body)
      event_body['ingestion_metadata'] = @ingestion_metadata.body if @ingestion_metadata.respond_to?(:body)
      %w[user_properties event_properties group_properties].each do |properties|
        next unless event_body[properties]
        # TODO: check ENUM
        # event_body[properties].transform_values! do |value|
        # value.is_a?(Enum) ? value.value : value
        # end
      end
      AmplitudeAnalytics.truncate(event_body)
    end

    def callback(status_code, message = nil)
      if @event_callback.respond_to?(:call)
        @event_callback.call(self, status_code, message)
      end
    end

    def to_s
      JSON.generate(event_body, sort_keys: true)
    end
  end

  # BaseEvent
  class BaseEvent < EventOptions
    def initialize(event_type, **kwargs)
      super(event_type, **kwargs)
    end

    def load_event_options(event_options)
      return if event_options.nil?

      EVENT_KEY_MAPPING.each_key do |key|
        send("#{key}=", event_options[key]) if respond_to?("#{key}=")
      end
    end
  end
end
