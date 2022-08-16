# Provides factory methods for storing singleton instance of Client
module AmplitudeExperiment
  @instances = {}
  @default_instance = '$default_instance'

  # Initializes a singleton Client. This method returns a default singleton instance, subsequent calls to
  #  init will return the initial instance regardless of input.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config Optional Config.
  def self.init(api_key, config = nil)
    @instances.store(@default_instance, RemoteEvaluationClient.new(api_key, config)) unless @instances.key?(@default_instance)
    @instances.fetch(@default_instance)
  end
end
