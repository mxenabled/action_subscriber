module ActionSubscriber
  module RabbitConnection
    def self.bunny_connection_options
      {
        :heartbeat                     => ::ActionSubscriber.configuration.heartbeat,
        :host                          => ::ActionSubscriber.configuration.host,
        :port                          => ::ActionSubscriber.configuration.port,
        :continuation_timeout          => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :automatically_recover         => true,
        :network_recovery_interval     => 1,
        :recover_from_connection_close => true,
      }
    end

    def self.connect!
      if ::RUBY_PLATFORM == "java"
        @connection = ::MarchHare.connect(march_hare_connection_options)
      else
        @connection = ::Bunny.new(bunny_connection_options)
        @connection.start
      end
      connection
    end

    def self.connected?
      connection && connection.connected?
    end

    def self.connection
      @connection
    end

    def self.march_hare_connection_options
      {
        :heartbeat_interval        => ::ActionSubscriber.configuration.heartbeat,
        :host                      => ::ActionSubscriber.configuration.host,
        :port                      => ::ActionSubscriber.configuration.port,
        :continuation_timeout      => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :automatically_recover     => true,
        :network_recovery_interval => 1,
      }
    end
  end
end
