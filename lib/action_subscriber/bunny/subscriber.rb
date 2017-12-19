module ActionSubscriber
  module Bunny
    module Subscriber
      include ::ActionSubscriber::Logging

      def bunny_consumers
        @bunny_consumers ||= []
      end

      def cancel_consumers!
        bunny_consumers.each(&:cancel)
        ::ActionSubscriber::ThreadPools.threadpools.each do |name, threadpool|
          threadpool.shutdown
        end
      end

      def setup_subscriptions!
        fail ::RuntimeError, "you cannot setup queues multiple times, this should only happen once at startup" unless subscriptions.empty?
        routes.each do |route|
          subscriptions << {
            :route => route,
            :queue => setup_queue(route),
          }
        end
      end

      def start_subscribers!
        subscriptions.each do |subscription|
          route = subscription[:route]
          queue = subscription[:queue]
          channel = queue.channel
          threadpool = ::ActionSubscriber::ThreadPools.threadpools.fetch(route.threadpool_name)
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
            run_env(env, threadpool)
          end
          bunny_consumers << consumer
          queue.subscribe_with(consumer)
        end
      end

      private

      def setup_queue(route)
        channel = ::ActionSubscriber::RabbitConnection.with_connection{|connection| connection.create_channel(nil, 1) }
        exchange = channel.topic(route.exchange, :durable => route.exchange_durable)
        queue = channel.queue(route.queue, :durable => route.durable)
        queue.bind(exchange, :routing_key => route.routing_key)
        queue
      end
    end
  end
end
