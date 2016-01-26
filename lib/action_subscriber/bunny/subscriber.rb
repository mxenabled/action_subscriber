module ActionSubscriber
  module Bunny
    module Subscriber
      include ::ActionSubscriber::Logging

      def bunny_consumers
        @bunny_consumers ||= []
      end

      def cancel_consumers!
        bunny_consumers.each(&:cancel)
      end

      def auto_pop!
        # Because threadpools can be large we want to cap the number
        # of times we will pop each time we poll the broker
        times_to_pop = [::ActionSubscriber::Threadpool.ready_size, ::ActionSubscriber.config.times_to_pop].min
        times_to_pop.times do
          queues.each do |route, queue|
            delivery_info, properties, encoded_payload = queue.pop(route.queue_subscription_options)
            next unless encoded_payload # empty queue
            ::ActiveSupport::Notifications.instrument "popped_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
            properties = {
              :action => route.action,
              :channel => queue.channel,
              :content_type => properties[:content_type],
              :delivery_tag => delivery_info.delivery_tag,
              :exchange => delivery_info.exchange,
              :headers => properties.headers,
              :message_id => nil,
              :routing_key => delivery_info.routing_key,
              :queue => queue.name,
            }
            env = ::ActionSubscriber::Middleware::Env.new(route.subscriber, encoded_payload, properties)
            enqueue_env(route.threadpool, env)
          end
        end
      end

      def auto_subscribe!
        queues.each do |route, queue|
          channel = queue.channel
          channel.prefetch(route.prefetch) if route.acknowledgements?
          consumer = ::Bunny::Consumer.new(channel, queue, channel.generate_consumer_tag, !route.acknowledgements?)
          consumer.on_delivery do |delivery_info, properties, encoded_payload|
            ::ActiveSupport::Notifications.instrument "received_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
            properties = {
              :action => route.action,
              :channel => queue.channel,
              :content_type => properties.content_type,
              :delivery_tag => delivery_info.delivery_tag,
              :exchange => delivery_info.exchange,
              :headers => properties.headers,
              :message_id => properties.message_id,
              :routing_key => delivery_info.routing_key,
              :queue => queue.name,
            }
            env = ::ActionSubscriber::Middleware::Env.new(route.subscriber, encoded_payload, properties)
            enqueue_env(route.threadpool, env)
          end
          bunny_consumers << consumer
          queue.subscribe_with(consumer)
        end
      end

      private

      def enqueue_env(threadpool, env)
        logger.info "RECEIVED #{env.message_id} from #{env.queue}"
        threadpool.async(env) do |env|
          ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
            ::ActionSubscriber.config.middleware.call(env)
          end
        end
      end
    end
  end
end
