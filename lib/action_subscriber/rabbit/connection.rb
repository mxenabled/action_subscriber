module ActionSubscriber
  module Rabbit
    class Connection
      # Used by the publisher when we are not sure if EM is running or not
      def self.connect!
        return ::AMQP.connection if connected?

        # For more info, see
        # http://rubyamqp.info/articles/connecting_to_broker/
        if ::EM.reactor_running?
          # If eventmachine is running we can connect to the broker,
          # but the event machine start may be delayed.  To protect
          # against that we connect on the next tick.
          ::EventMachine.next_tick do
            ::AMQP.connection = ::AMQP.connect(connection_options)
          end
        else
          # If eventmachine is not running, start eventmachine in a new thread
          # because eventmachine will block the main thread
          ::Thread.new { ::AMQP.start(connection_options) }
        end

        ::Thread.pass until connected?

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
          :host => ::ActionSubscriber::Rabbit::Configuration.config.host,
          :port => ::ActionSubscriber::Rabbit::Configuration.config.port
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
end
