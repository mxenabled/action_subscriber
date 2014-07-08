module ActionSubscriber
  module Bunny
    module Subscriber
      def auto_pop!
        # Because threadpools can be large we want to cap the number
        # of times we will pop each time we poll the broker
        times_to_pop = [::ActionSubscriber::Threadpool.ready_size, ::ActionSubscriber.config.times_to_pop].min
        times_to_pop.times do
          queues.each do |queue|
            delivery_info, properties, encoded_payload = queue.pop(queue_subscription_options)
            next unless encoded_payload # empty queue
            ::ActiveSupport::Notifications.instrument "popped_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
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
            ::ActiveSupport::Notifications.instrument "received_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
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

      private

      def enqueue_env(env)
        ::ActionSubscriber::Threadpool.pool.async(env) do |env|
          ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key do
            ::ActionSubscriber.config.middleware.call(env)
          end
        end
      end
    end
  end
end
