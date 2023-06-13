# Provides factory methods for storing singleton instance of Client
module AmplitudeExperiment
  @local_instance = {}
  @remote_instance = {}

  # Initializes a singleton Client. This method returns a default singleton instance, subsequent calls to
  #  init will return the initial instance regardless of input.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config Optional Config.
  def self.initialize_remote(api_key, config = nil)
    unless @remote_instance.key?(api_key)
      @remote_instance.store(api_key, RemoteEvaluationClient.new(api_key, config))
    end
    @remote_instance.fetch(api_key)
  end

  # Initializes a local evaluation Client. A local evaluation client can evaluate local flags or experiments for a
  # user without requiring a remote call to the amplitude evaluation server. In order to best leverage local
  # evaluation, all flags, and experiments being evaluated server side should be configured as local.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config Optional Config.
  def self.initialize_local(api_key, config = nil)
    unless @local_instance.key?(api_key)
      @local_instance.store(api_key, LocalEvaluationClient.new(api_key, config))
    end
    @local_instance.fetch(api_key)
  end
end
