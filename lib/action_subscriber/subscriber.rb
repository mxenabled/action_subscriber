module ActionSubscriber
  module Subscriber
    def auto_pop!
      # Because threadpools can be large we want to cap the number
      # of times we will pop each time we poll the broker
      times_to_pop = [::ActionSubscriber::Threadpool.ready_size, ::ActionSubscriber.config.times_to_pop].min
      times_to_pop.times do
        queues.each do |queue|
          delivery_info, properties, encoded_payload = queue.pop(queue_subscription_options)
          next unless encoded_payload # empty queue
          properties = {
            :acknowledger => nil,
            :content_type => properties[:content_type],
            :exchange => delivery_info.exchange,
            :message_id => nil,
            :routing_key => delivery_info.routing_key,
          }
          env = ::ActionSubscriber::Middleware::Env.new(self, encoded_payload, properties)
          enqueue_env(env)
        end
      end
    end

    def auto_subscribe!
      queues.each do |queue|
        queue.subscribe(queue_subscription_options) do |delivery_info, properties, encoded_payload|
          properties = {
            :acknowledger => nil,
            :content_type => properties.content_type,
            :exchange => delivery_info.exchange,
            :message_id => properties.message_id,
            :routing_key => delivery_info.routing_key,
          }
          env = ::ActionSubscriber::Middleware::Env.new(self, encoded_payload, properties)
          enqueue_env(env)
        end
      end
    end

    def queues
      @_queues ||= []
    end

    def setup_queue!(method_name, exchange_name)
      queue_name = queue_name_for_method(method_name)
      routing_key_name = routing_key_name_for_method(method_name)

      channel = ::ActionSubscriber::RabbitConnection.connection.create_channel
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

    private

    def enqueue_env(env)
      ::ActionSubscriber::Threadpool.pool.async(env) do |env|
        ::ActionSubscriber.config.middleware.call(env)
      end
    end
  end
end
