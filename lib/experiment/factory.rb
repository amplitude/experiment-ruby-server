# Provides factory methods for storing singleton instance of Client
module Experiment
  @instances = {}
  @default_instance = '$default_instance'

  # Initializes a singleton Client.
  #
  # @param [String] api_key The environment API Key
  # @param [Config] config
  def self.init(api_key, config = nil)
    @instances.store(@default_instance, Client.new(api_key, config)) unless @instances.key?(@default_instance)
    @instances.fetch(@default_instance)
  end
end
