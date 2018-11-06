module ActionSubscriber
  module MarchHare
    module Subscriber
      include ::ActionSubscriber::Logging

      def cancel_consumers!
        march_hare_consumers.each(&:cancel)
        ::ActionSubscriber::ThreadPools.threadpools.each do |name, threadpool|
          threadpool.shutdown
        end
      end

      def march_hare_consumers
        @march_hare_consumers ||= []
      end
      
      def set_march_hare_consumers(consumers)
        @march_hare_consumers = consumers
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
      
      def start_subscription!(subscription)
          route = subscription[:route]
          queue = subscription[:queue]
          queue.channel.prefetch = route.prefetch if route.acknowledgements?
          threadpool = ::ActionSubscriber::ThreadPools.threadpools.fetch(route.threadpool_name)

          cancel = {
            :on_cancellation => Proc.new { |channel, consumer| 
              channel.close
              set_march_hare_consumers(march_hare_consumers.reject { |march_hare_consumer| march_hare_consumer == consumer })

              subscription[:queue] = setup_queue(route)
              start_subscription!(subscription)
            }
          }
          consumer = queue.subscribe(cancel.merge(route.queue_subscription_options)) do |metadata, encoded_payload|
            ::ActiveSupport::Notifications.instrument "received_event.action_subscriber", :payload_size => encoded_payload.bytesize, :queue => queue.name
            properties = {
              :action => route.action,
              :channel => queue.channel,
              :content_type => metadata.content_type,
              :delivery_tag => metadata.delivery_tag,
              :exchange => metadata.exchange,
              :headers => _normalized_headers(metadata),
              :message_id => metadata.message_id,
              :routing_key => metadata.routing_key,
              :queue => queue.name,
              :uses_acknowledgements => route.acknowledgements?,
            }
            env = ::ActionSubscriber::Middleware::Env.new(route.subscriber, encoded_payload, properties)
            run_env(env, threadpool)
          end

          march_hare_consumers << consumer
      end

      def start_subscribers!
        route_set = self
        subscriptions.each do |subscription|
          start_subscription! subscription
        end
      end

      private

      def setup_queue(route)
        channel = ::ActionSubscriber::RabbitConnection.with_connection{|connection| connection.create_channel }
        exchange = channel.topic(route.exchange)
        queue = channel.queue(route.queue, :durable => route.durable)
        queue.bind(exchange, :routing_key => route.routing_key)
        queue
      end

      def _normalized_headers(metadata)
        return {} unless metadata.headers
        metadata.headers.each_with_object({}) do |(header,value), hash|
          hash[header] = value.to_s
        end
      end
    end
  end
end
