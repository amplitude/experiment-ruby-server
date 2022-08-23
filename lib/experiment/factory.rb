# Provides factory methods for storing singleton instance of Client
module AmplitudeExperiment
  @local_instance = {}
  @remote_instance = {}
  @default_instance = '$default_instance'

  # Initializes a singleton Client. This method returns a default singleton instance, subsequent calls to
  #  init will return the initial instance regardless of input.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config Optional Config.
  def self.initialize_remote(api_key, config = nil)
    unless @local_instance.key?(@default_instance)
      @local_instance.store(@default_instance, RemoteEvaluationClient.new(api_key, config))
    end
    @local_instance.fetch(@default_instance)
  end

  # Initializes a local evaluation Client. A local evaluation client can evaluate local flags or experiments for a
  # user without requiring a remote call to the amplitude evaluation server. In order to best leverage local
  # evaluation, all flags, and experiments being evaluated server side should be configured as local.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config Optional Config.
  def self.initialize_local(api_key, config = nil)
    unless @remote_instance.key?(@default_instance)
      @remote_instance.store(@default_instance, LocalEvaluationClient.new(api_key, config))
    end
    @remote_instance.fetch(@default_instance)
  end
end
