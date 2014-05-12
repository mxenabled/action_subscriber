module ActionSubscriber
  module RabbitConnection
    def self.connect!
      @connection = ::Bunny.new(connection_options)
      @connection.start
      connection
    end

    def self.connected?
      connection && connection.connected?
    end

    def self.connection
      @connection
    end

    def self.connection_options
      {
        :heartbeat                 => ::ActionSubscriber.configuration.heartbeat,
        :host                      => ::ActionSubscriber.configuration.host,
        :port                      => ::ActionSubscriber.configuration.port,
        :continuation_timeout      => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :automatically_recover     => true,
        :network_recovery_interval => 1,
      }
    end
  end
end
