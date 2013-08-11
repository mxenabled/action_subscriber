module ActionSubscriber
  module RabbitConnection
    # Must be called inside an EM.run block
    #
    def self.connect!
      ::AMQP.connection = ::AMQP.connect(connection_options)
      set_connection_reconnect

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
        :host => ::ActionSubscriber.configuration.host,
        :port => ::ActionSubscriber.configuration.port
      }
    end

    def self.new_channel
      channel = ::AMQP::Channel.new(::AMQP.connection)
      channel.auto_recovery = true
      return channel
    end

    def self.set_connection_reconnect
      # AMQP::Session#reconnect(force = false, period = 2)
      # doesn't immediately force reconnect and waits 2 seconds before
      # trying to reconnect (infinitely retries)
      # http://rubyamqp.info/articles/error_handling/#handling_network_connection_interruptions
      ::AMQP.connection.on_tcp_connection_loss do |session, settings|
        session.reconnect
      end
    end
  end
end
