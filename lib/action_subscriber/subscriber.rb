module ActionSubscriber
  module Subscriber
    def auto_pop!
      nil_pops = 0

      # Each "turn" of the timer should look at the available threads
      # and attempt to fill them in with work, if it gets a nil pop
      # (which means no jobs are avail) then we will track it and 
      # return from the method after 2; this allows us to make the
      # timer interval greater because auto_pop! is more "eager"
      while ::ActionSubscriber::Threadpool.ready? && nil_pops < 2
        queues.each do |queue|
          next unless ::ActionSubscriber::Threadpool.ready?

          queue.pop(queue_subscription_options) do |header, payload|
            if payload
              subscriber = self.new(header, payload)
              ::ActionSubscriber::Threadpool.perform_async(subscriber)
            else
              nil_pops = nil_pops + 1
            end
          end

        end
      end
    end

    def auto_subscribe!
      queues.each do |queue|
        queue.subscribe(queue_subscription_options) do |header, payload|
          subscriber = self.new(header, payload)
          ::ActionSubscriber::Threadpool.perform_async(subscriber)
        end
      end
    end

    def queues
      @_queues ||= []
    end

    def setup_queue!(method_name, exchange_name)
      queue_name = queue_name_for_method(method_name)
      routing_key_name = routing_key_name_for_method(method_name)

      channel = ::ActionSubscriber::RabbitConnection.new_channel
      exchange = channel.__send__('topic', exchange_name)
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
