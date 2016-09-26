module ActionSubscriber
  module Babou
    ##
    # Class Methods
    #
    def self.start_subscribers
      reload_active_record
      ::ActionSubscriber.setup_default_connection!
      ::ActionSubscriber.setup_subscriptions!
      ::ActionSubscriber.print_subscriptions
      ::ActionSubscriber.start_subscribers!
      logger.info "Action Subscriber connected"

      while true
        sleep 1.0 #just hang around waiting for messages
        break if shutting_down?
      end
    end

    def self.logger
      ::ActionSubscriber::Logging.logger
    end

    def self.reload_active_record
      if defined?(::ActiveRecord::Base) && !::ActiveRecord::Base.connected?
        ::ActiveRecord::Base.establish_connection
      end
    end

    def self.shutting_down?
      !!@shutting_down
    end

    def self.stop_server!
      # this method is called from within a TRAP context so we can't use the logger
      @shutting_down = true
      puts "Stopping subscribers..."
      ::ActionSubscriber.stop_subscribers!
      puts "Shutting down"
      ::Thread.new do
        ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
      end.join
    end
  end
end
