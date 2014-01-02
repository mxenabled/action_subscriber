module ActionSubscriber
  module RabbitConnection
    # Must be called inside an EM.run block
    #
    def self.connect!
      ::AMQP.connection = ::AMQP.connect(connection_options)

      setup_recovery

      return ::AMQP.connection
    end

    def self.connected?
      connection && ::AMQP.connection.connected?
    end

    def self.connection
      ::AMQP.connection
    end

    def self.connection_options
      {
        :heartbeat => ::ActionSubscriber.configuration.heartbeat,
        :host      => ::ActionSubscriber.configuration.host,
        :port      => ::ActionSubscriber.configuration.port
      }
    end

    def self.new_channel
      channel = ::AMQP::Channel.new(::AMQP.connection)
      channel.auto_recovery = true
      return channel
    end

    def self.setup_recovery
      # When the server fails to respond to a heartbeat, it is assumed
      # to be dead. By closing the underlying EventMachine connection,
      # a connection loss is triggered in AMQP .
      self.connection.on_skipped_heartbeats do |session|
        EventMachine.close_connection(session.signature, false)
      end

      # When the connection loss is triggered, we reconnect, which
      # also runs the auto-recovery code
      self.connection.on_tcp_connection_loss do |session, settings|
        session.reconnect(false, 1)
      end
    end
  end
end
