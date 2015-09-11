require 'thread'

module ActionSubscriber
  module RabbitConnection
    SUBSCRIBER_CONNECTION_MUTEX = ::Mutex.new
    PUBLISHER_CONNECTION_MUTEX = ::Mutex.new

    def self.publisher_connected?
      publisher_connection.try(:connected?)
    end

    def self.publisher_connection
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        return @publisher_connection if @publisher_connection
        @publisher_connection = create_connection
      end
    end

    def self.publisher_disconnect!
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        if @publisher_connection && @publisher_connection.connected?
          @publisher_connection.close
        end

        @publisher_connection = nil
      end
    end

    def self.subscriber_connected?
      subscriber_connection.try(:connected?)
    end

    def self.subscriber_connection
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        return @subscriber_connection if @subscriber_connection
        @subscriber_connection = create_connection
      end
    end

    def self.subscriber_disconnect!
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        if @subscriber_connection && @subscriber_connection.connected?
          @subscriber_connection.close
        end

        @subscriber_connection = nil
      end
    end

    # Private API
    def self.create_connection
      if ::RUBY_PLATFORM == "java"
        connection = ::MarchHare.connect(connection_options)
      else
        connection = ::Bunny.new(connection_options)
        connection.start
        connection
      end
    end
    private_class_method :create_connection

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
    private_class_method :connection_options
  end
end
