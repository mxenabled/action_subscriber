module ActionSubscriber
  module RabbitConnection
    def self.connect!
      @connection = ::Bunny.new
      @connection.start
      # setup_recovery # TODO figure out how we want to handle recovery (provided by bunny automatically?)
      connection
    end

    def self.connected?
      connection && ::AMQP.connection.connected?
    end

    def self.connection
      @connection
    end

    def self.connection_options
      {
        :heartbeat => ::ActionSubscriber.configuration.heartbeat,
        :host      => ::ActionSubscriber.configuration.host,
        :port      => ::ActionSubscriber.configuration.port,
        :timeout   => ::ActionSubscriber.configuration.timeout
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
        last_heartbeat = session.instance_variable_get(:@last_server_heartbeat)
        last_heartbeat = "\"#{Time.now - last_heartbeat} seconds ago\"" if last_heartbeat
        session.logger.info "[action_subscriber] closing rabbitmq connection heartbeat_interval=#{session.heartbeat_interval} last_heartbeat=#{last_heartbeat}"

        EventMachine.close_connection(session.signature, false)
      end

      # When the connection loss is triggered, we reconnect, which
      # also runs the auto-recovery code
      self.connection.on_tcp_connection_loss do |session, settings|
        session.logger.info "[action_subscriber] connection lost, initiating recovery"
        session.reconnect(false, 1)
      end

      connection.after_recovery do |session|
        session.logger.info("[action_subscriber] connection recovered")
      end
    end
  end
end
