module AmplitudeExperiment
  # Persist Http Client to reuse connection and reduce IO. Connections are
  # shared by api key.
  #
  # WARNING: these connections are not safe for concurrent requests. Callers
  # must synchronize requests per connection.
  class PersistentHttpClient
    DEFAULT_OPTIONS = { read_timeout: 80 }.freeze

    class << self
      # url: URI / String
      # options: any options that Net::HTTP.new accepts
      # api_key: the deployment key for ensuring different deployments dont
      # share connections.
      def get(url, options = {}, api_key)
        uri = url.is_a?(URI) ? url : URI(url)
        connection_manager.get_client(uri, options, api_key)
      end

      private

      # each thread gets its own connection manager
      def connection_manager
        # before getting a connection manager
        # we first clear all old ones
        remove_old_managers
        Thread.current[:http_connection_manager] ||= new_manager
      end

      def new_manager
        # create a new connection manager in a thread safe way
        mutex.synchronize do
          manager = ConnectionManager.new
          connection_managers << manager
          manager
        end
      end

      def remove_old_managers
        mutex.synchronize do
          removed = connection_managers.reject!(&:stale?)
          (removed || []).each(&:close_connections!)
        end
      end

      # mutex isn't needed for CRuby, but might be needed
      # for other Ruby implementations
      def mutex
        @mutex ||= Mutex.new
      end

      def connection_managers
        @connection_managers ||= []
      end
    end

    # connection manager represents
    # a cache of all keep-alive connections
    # in a current thread
    class ConnectionManager
      # if a client wasn't used within this time range
      # it gets removed from the cache and the connection closed.
      # This helps to make sure there are no memory leaks.
      STALE_AFTER = 300 # 5 minutes

      # Seconds to reuse the connection of the previous request. If the idle time is less than this Keep-Alive Timeout,
      # Net::HTTP reuses the TCP/IP socket used by the previous communication. Source: Ruby docs
      KEEP_ALIVE_TIMEOUT = 30 # seconds

      # KEEP_ALIVE_TIMEOUT vs STALE_AFTER
      # STALE_AFTER - how long an Net::HTTP client object is cached in ruby
      # KEEP_ALIVE_TIMEOUT - how long that client keeps TCP/IP socket open.

      attr_accessor :clients_store, :last_used

      def initialize
        self.clients_store = {}
        self.last_used = Time.now
      end

      def get_client(uri, options, api_key)
        mutex.synchronize do
          # refresh the last time a client was used,
          # this prevents the client from becoming stale
          self.last_used = Time.now

          # we use params as a cache key for clients.
          # 2 connections to the same host but with different
          # options are going to use different HTTP clients
          params = [uri.host, uri.port, options, api_key]
          client = clients_store[params]

          return client if client

          client = Net::HTTP.new(uri.host, uri.port)
          client.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

          # set SSL to true if a scheme is https
          client.use_ssl = uri.scheme == 'https'

          # dynamically set Net::HTTP options
          DEFAULT_OPTIONS.merge(options).each_pair do |key, value|
            client.public_send("#{key}=", value)
          end

          # open connection
          client.start

          # cache the client
          clients_store[params] = client

          client
        end
      end

      # close connections for each client
      def close_connections!
        mutex.synchronize do
          clients_store.values.each(&:finish)
          self.clients_store = {}
        end
      end

      def stale?
        Time.now - last_used > STALE_AFTER
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
