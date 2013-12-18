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
      # When the server fails to respond to a heartbeat, we assume that it
      # is dead and attempt to reconnect with auto recovery. To accomplish
      # this, we must timeout the underlying EventMachine connection. If we
      # reconnected manually, the auto recovery code would not be triggered,
      #
      # Forcing a timeout in EventMachine is a two step process:
      #   1. Pause all activity on the connection
      #   2. Configure the connection to timeout when there is no activity
      self.connection.on_skipped_heartbeats do |session|
        # This completes step 1
        session.pause

        # This completes step 2. Remember that when we run this code a
        # skipped heartbeat has already been detected. We want the
        # timeout, and consequently auto recovery, to happen immediately
        session.comm_inactivity_timeout = 0.01
      end

      self.connection.on_tcp_connection_loss do |session, settings|
        # A reconnect also resets the inactivity timeout to 0.0 and
        # resumes the connection
        session.reconnect(false, 1)
      end
    end
  end
end
