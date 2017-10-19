module ActionSubscriber
  module Babou
    ##
    # Class Methods
    #
    def self.start_subscribers
      reload_active_record
      ::ActionSubscriber.setup_default_threadpool!
      ::ActionSubscriber.setup_subscriptions!
      ::ActionSubscriber.print_subscriptions
      ::ActionSubscriber.start_subscribers!
      logger.info "Action Subscriber connected"

      while true
        sleep 1.0 #just hang around waiting for messages
        break if shutting_down?
      end

      logger.info "Stopping subscribers..."
      ::ActionSubscriber.stop_subscribers!
      logger.info "Shutting down"
      ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
      logger.info "Shutdown complete"
      exit(0)
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
      @shutting_down = true
    end
  end
end
