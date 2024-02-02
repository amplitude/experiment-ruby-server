# Provides factory methods for storing singleton instance of Client
module AmplitudeExperiment
  @local_instance = {}
  @remote_instance = {}

  # Initializes a singleton Client. This method returns a default singleton instance, subsequent calls to
  #  init will return the initial instance regardless of input.
  #
  # @param [String] api_key The Amplitude Project API Key used in the client. If a deployment key is provided in
  # the config, it will be used instead.
  # @param [Config] config Optional Config.
  def self.initialize_remote(api_key, config = nil)
    used_key = config&.deployment_key.nil? ? api_key : config.deployment_key
    @remote_instance.store(used_key, RemoteEvaluationClient.new(used_key, config)) unless @remote_instance.key?(used_key)
    @remote_instance.fetch(used_key)
  end

  # Initializes a local evaluation Client. A local evaluation client can evaluate local flags or experiments for a
  # user without requiring a remote call to the amplitude evaluation server. In order to best leverage local
  # evaluation, all flags, and experiments being evaluated server side should be configured as local.
  #
  # @param [String] api_key The Amplitude Project API Key used in the client. If a deployment key is provided in
  # the config, it will be used instead.
  # @param [Config] config Optional Config.
  def self.initialize_local(api_key, config = nil)
    used_key = config&.deployment_key.nil? ? api_key : config.deployment_key
    @local_instance.store(used_key, LocalEvaluationClient.new(used_key, config)) unless @local_instance.key?(used_key)
    @local_instance.fetch(used_key)
  end
end
