module AmplitudeExperiment
  class Event
    attr_accessor :user_id, :device_id, :time, :location_lat, :location_lng, :app_version, :version_name
    attr_accessor :library, :platform, :os_name, :os_version, :device_brand, :device_manufacturer
    attr_accessor :device_model, :carrier, :country, :region, :city, :dma, :idfa, :idfv, :adid, :android_id
    attr_accessor :language, :ip, :price, :quantity, :revenue, :product_id, :revenue_type, :event_id
    attr_accessor :session_id, :insert_id, :plan, :ingestion_metadata, :partner_id, :user_agent
    attr_accessor :android_app_set_id, :extra, :event_type, :event_properties, :user_properties
    attr_accessor :group_properties, :groups

    def initialize(device_id: nil, user_id: nil, time: nil, location_lat: nil, location_lng: nil,
                   app_version: nil, version_name: nil, library: nil, platform: nil, os_name: nil,
                   os_version: nil, device_brand: nil, device_manufacturer: nil, device_model: nil,
                   carrier: nil, country: nil, region: nil, city: nil, dma: nil, idfa: nil, idfv: nil,
                   adid: nil, android_id: nil, language: nil, ip: nil, price: nil, quantity: nil,
                   revenue: nil, product_id: nil, revenue_type: nil, event_id: nil, session_id: nil,
                   insert_id: nil, plan: nil, ingestion_metadata: nil, partner_id: nil, user_agent: nil,
                   android_app_set_id: nil, extra: nil, event_type: nil, event_properties: nil,
                   user_properties: nil, group_properties: nil, groups: nil)
      @user_id = user_id
      @device_id = device_id
      @time = time
      @location_lat = location_lat
      @location_lng = location_lng
      @app_version = app_version
      @version_name = version_name
      @library = library
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
      @idfa = idfa
      @idfv = idfv
      @adid = adid
      @android_id = android_id
      @language = language
      @ip = ip
      @price = price
      @quantity = quantity
      @revenue = revenue
      @product_id = product_id
      @revenue_type = revenue_type
      @event_id = event_id
      @session_id = session_id
      @insert_id = insert_id
      @plan = plan
      @ingestion_metadata = ingestion_metadata
      @partner_id = partner_id
      @user_agent = user_agent
      @android_app_set_id = android_app_set_id
      @extra = extra || {}
      @event_type = event_type
      @event_properties = event_properties || {}
      @user_properties = user_properties || {}
      @group_properties = group_properties || {}
      @groups = groups || {}
    end

    def as_json(_options = {})
      {
        user_id: @user_id,
        device_id: @device_id,
        time: @time,
        location_lat: @location_lat,
        location_lng: @location_lng,
        app_version: @app_version,
        version_name: @version_name,
        library: @library,
        platform: @platform,
        os_name: @os_name,
        os_version: @os_version,
        device_brand: @device_brand,
        device_manufacturer: @device_manufacturer,
        device_model: @device_model,
        carrier: @carrier,
        country: @country,
        region: @region,
        city: @city,
        dma: @dma,
        idfa: @idfa,
        idfv: @idfv,
        adid: @adid,
        android_id: @android_id,
        language: @language,
        ip: @ip,
        price: @price,
        quantity: @quantity,
        revenue: @revenue,
        product_id: @product_id,
        revenue_type: @revenue_type,
        event_id: @event_id,
        session_id: @session_id,
        insert_id: @insert_id,
        plan: @plan,
        ingestion_metadata: @ingestion_metadata,
        partner_id: @partner_id,
        user_agent: @user_agent,
        android_app_set_id: @android_app_set_id,
        extra: @extra,
        event_type: @event_type,
        event_properties: @event_properties,
        user_properties: @user_properties,
        group_properties: @group_properties,
        groups: @groups
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end
  end
end
