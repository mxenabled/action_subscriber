module ActionSubscriber
  module DSL
    def at_least_once!
      @_acknowledge_messages = true
      around_filter :_at_least_once_filter
      ActionSubscriber::DeadLetterExchange.setup_retries_queue
    end

    def at_most_once!
      @_acknowledge_messages = true
      around_filter :_at_most_once_filter
    end

    def acknowledge_messages?
      !!@_acknowledge_messages
    end

    def around_filter(filter_method)
      around_filters << filter_method
    end

    def around_filters
      @_around_filters ||= []
    end

    # Explicitly set the name of the exchange
    #
    def exchange_names(*names)
      @_exchange_names ||= []
      @_exchange_names += names.flatten.map(&:to_s)

      if @_exchange_names.empty?
        return [ ::ActionSubscriber.config.default_exchange ]
      else
        return @_exchange_names.compact.uniq
      end
    end
    alias_method :exchange, :exchange_names

    def manual_acknowledgement!
      @_acknowledge_messages = true
    end

    def no_acknowledgement!
      @_acknowledge_messages = false
    end

    # Explicitly set the name of a queue for the given method route
    #
    # Ex.
    #   queue_for :created, "derp.derp"
    #   queue_for :updated, "foo.bar"
    #
    def queue_for(method, queue_name)
      @_queue_names ||= {}
      @_queue_names[method] = queue_name
    end

    def queue_names
      @_queue_names ||= {}
    end

    def queue_subscription_options
      @_queue_subscription_options ||= { :manual_ack => acknowledge_messages? }
    end

    def remote_application_name(name = nil)
      @_remote_application_name = name if name
      @_remote_application_name
    end
    alias_method :publisher, :remote_application_name

    # Explicitly set the whole routing key to use for a given method route.
    #
    def routing_key_for(method, routing_key_name)
      @_routing_key_names ||= {}
      @_routing_key_names[method] = routing_key_name
    end

    def routing_key_names
      @_routing_key_names ||= {}
    end

    def run_action_with_filters(env, action)
      subscriber_instance = self.new(env)
      final_block = Proc.new { subscriber_instance.public_send(action) }

      first_proc = around_filters.reverse.reduce(final_block) do |block, filter|
        Proc.new { subscriber_instance.send(filter, &block) }
      end
      first_proc.call
    end
  end
end
