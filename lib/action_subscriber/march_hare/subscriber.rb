module ActionSubscriber
  module MarchHare
    module Subscriber
      def auto_pop!
        # Because threadpools can be large we want to cap the number
        # of times we will pop each time we poll the broker
        times_to_pop = [::ActionSubscriber::Threadpool.ready_size, ::ActionSubscriber.config.times_to_pop].min
        times_to_pop.times do
          queues.each do |queue|
            header, encoded_payload = queue.pop(queue_subscription_options)
            next unless encoded_payload
            ::ActiveSupport::Notifications.instrument "popped_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
            properties = {
              :acknowledger => header,
              :content_type => header.content_type,
              :exchange => header.exchange,
              :message_id => header.message_id,
              :routing_key => header.routing_key,
            }
            env = ::ActionSubscriber::Middleware::Env.new(self, encoded_payload, properties)
            enqueue_env(env)
          end
        end

      rescue ::MarchHare::ChannelAlreadyClosed => e
        # The connection has gone down, we can just try again on the next pop
      end

      def auto_subscribe!
        queues.each do |queue|
          queue.subscribe(queue_subscription_options) do |header, encoded_payload|
            ::ActiveSupport::Notifications.instrument "received_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
            properties = {
              :acknowledger => header,
              :content_type => header.content_type,
              :exchange => header.exchange,
              :message_id => header.message_id,
              :routing_key => header.routing_key,
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
