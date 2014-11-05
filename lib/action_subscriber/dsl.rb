module ActionSubscriber
  module DSL
    def acknowledge_messages?
      !!@_acknowledge_messages
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
  end
end
