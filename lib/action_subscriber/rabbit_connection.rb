require 'thread'

module ActionSubscriber
  module RabbitConnection
    CONNECTION_MUTEX = ::Mutex.new

    def self.connect!
      CONNECTION_MUTEX.synchronize do
        return @connection if @connection
        @connection = new_connection
      end
    end

    def self.connected?
      connection && connection.connected?
    end

    def self.connection
      connect!
    end

    def self.connection_options
      {
        :heartbeat                     => ::ActionSubscriber.configuration.heartbeat,
        :hosts                         => ::ActionSubscriber.configuration.hosts,
        :port                          => ::ActionSubscriber.configuration.port,
        :continuation_timeout          => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :automatically_recover         => true,
        :network_recovery_interval     => 1,
        :recover_from_connection_close => true,
      }
    end

    def self.new_connection
        if ::RUBY_PLATFORM == "java"
          ::MarchHare.connect(connection_options)
        else
          connection = ::Bunny.new(connection_options)
          connection.start
          connection
        end
    end
  end
end
