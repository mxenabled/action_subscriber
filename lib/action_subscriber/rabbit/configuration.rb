module ActionSubscriber
  module Rabbit
    class Configuration
      attr_accessor :host, :port

      ##
      # Constructor!
      #
      def initialize
        self.host = 'localhost'
        self.port = 5672
      end

      ##
      # Class methods
      #
      def self.configuration
        @configuration ||= self.new
      end

      def self.configure
        yield(configuration) if block_given?
      end

      def self.load_from_yaml(relative_config_path)
        absolute_config_path = ::File.expand_path(relative_config_path)
        rabbit_config = ::YAML.load_file(absolute_config_path, :safe => true)[::ActionSubscriber.env]

        self.configure do |config|
          config.host = rabbit_config["host"]
          config.port = rabbit_config["port"]
        end
      end

      ##
      # Class aliases
      #
      class << self
        alias_method :config, :configuration
      end
    end
  end
end
