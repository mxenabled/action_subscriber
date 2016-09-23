module ActionSubscriber
  module Babou
    ##
    # Class Methods
    #

    def self.auto_pop!
      @pop_mode = true
      reload_active_record
      ::ActionSubscriber.setup_default_connection!
      sleep_time = ::ActionSubscriber.configuration.pop_interval.to_i / 1000.0

      ::ActionSubscriber.start_queues
      logger.info "Action Subscriber is popping messages every #{sleep_time} seconds."

      # How often do we want the timer checking for new pops
      # since we included an eager popper we decreased the
      # default check interval to 100m
      while true
        ::ActionSubscriber.auto_pop! unless shutting_down?
        sleep sleep_time
        break if shutting_down?
      end
    end

    def self.pop?
      !!@pop_mode
    end

    def self.start_subscribers
      @prowl_mode = true
      reload_active_record
      ::ActionSubscriber.setup_default_connection!

      ::ActionSubscriber.start_subscribers
      logger.info "Action Subscriber connected"

      while true
        sleep 1.0 #just hang around waiting for messages
        break if shutting_down?
      end
    end

    def self.prowl?
      !!@prowl_mode
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

    def self.stop_receving_messages!
      @shutting_down = true
      ::Thread.new do
        ::ActionSubscriber.stop_subscribers!
        logger.info "stopped all subscribers"
      end.join
    end

    def self.stop_server!
      # this method is called from within a TRAP context so we can't use the logger
      puts "Stopping server..."
      wait_loops = 0
      ::ActionSubscriber::Babou.stop_receving_messages!

      puts "waiting for threadpools to empty (maximum wait of #{::ActionSubscriber.configuration.seconds_to_wait_for_graceful_shutdown}sec)"
      loop do
        wait_loops = wait_loops + 1
        any_threadpools_busy = false
        ::ActionSubscriber::Threadpool.pools.each do |name, pool|
          next if pool.busy_size <= 0
          puts "  -- #{name} (remaining: #{pool.busy_size})"
          any_threadpools_busy = true
        end
        ::ActionSubscriber::RabbitConnection.connection_threadpools.each do |name, executor|
          next if executor.get_active_count <= 0
          puts "  -- Connection #{name} (remaining: #{executor.get_active_count})"
          any_threadpools_busy = true
        end
        break unless any_threadpools_busy
        break if wait_loops >= ::ActionSubscriber.configuration.seconds_to_wait_for_graceful_shutdown
        Thread.pass
        sleep 1
      end
      puts "threadpool empty. Shutting down"
      ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
    end
  end
end
