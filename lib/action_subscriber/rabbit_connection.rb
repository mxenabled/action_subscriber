require 'thread'

module ActionSubscriber
  module RabbitConnection
    SUBSCRIBER_CONNECTION_MUTEX = ::Mutex.new
    NETWORK_RECOVERY_INTERVAL = 1.freeze

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
          loop do
            break if @subscriber_connection.closed?
          end
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
        :continuation_timeout          => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :heartbeat                     => ::ActionSubscriber.configuration.heartbeat,
        :hosts                         => ::ActionSubscriber.configuration.hosts,
        :pass                          => ::ActionSubscriber.configuration.password,
        :port                          => ::ActionSubscriber.configuration.port,
        :user                          => ::ActionSubscriber.configuration.username,
        :vhost                         => ::ActionSubscriber.configuration.virtual_host,
        :automatically_recover         => true,
        :network_recovery_interval     => NETWORK_RECOVERY_INTERVAL,
        :recover_from_connection_close => true,
      }
    end
    private_class_method :connection_options
  end
end
