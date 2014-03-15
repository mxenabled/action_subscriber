module ActionSubscriber
  module Subscriber
    def auto_pop!
      # Because threadpools can be large we want to cap the number
      # of times we will pop each time we poll the broker
      times_to_pop = [::ActionSubscriber::Threadpool.ready_size, ::ActionSubscriber.config.times_to_pop].min
      times_to_pop.times do
        queues.each do |queue|
          next unless ::ActionSubscriber::Threadpool.ready?

          queue.pop(queue_subscription_options) do |header, encoded_payload|
            if encoded_payload
              env = ::ActionSubscriber::Middleware::Env.new(self, header, encoded_payload)
              ::ActionSubscriber::Threadpool.perform_async(env)
            end
          end
        end
      end
    end

    def auto_subscribe!
      queues.each do |queue|
        queue.subscribe(queue_subscription_options) do |header, encoded_payload|
          # TODO: Initialize this in the router, at the end of the stack
          env = ::ActionSubscriber::Middleware::Env.new(self, header, encoded_payload)
          ::ActionSubscriber::Threadpool.perform_async(env)
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
