module ActionSubscriber
  module DefaultRouting
    def queues
      @_queues ||= []
    end

    def setup_queue!(method_name, exchange_name)
      queue_name = queue_name_for_method(method_name)
      routing_key_name = routing_key_name_for_method(method_name)

      channel = connection.create_channel
      exchange = channel.topic(exchange_name)
      queue = channel.queue(queue_name)
      queue.bind(exchange, :routing_key => routing_key_name)
      return queue
    end

    def setup_queues!
      exchange_names.each do |exchange_name|
        subscribable_methods.each do |method_name|
          queues << setup_queue!(method_name, exchange_name)
        end
      end
    end
  end
end
