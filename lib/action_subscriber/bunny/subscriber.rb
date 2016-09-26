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

      def create_queue(channel, queue_name, queue_options)
        ::Bunny::Queue.new(channel, queue_name, queue_options)
      end

      def print_subscriptions
        routes.group_by(&:subscriber).each do |subscriber, routes|
          logger.info subscriber.name
          routes.each do |route|
            logger.info "  -- method: #{route.action}"
            logger.info "    --  connection: #{route.connection_name}"
            logger.info "    -- concurrency: #{route.concurrency}"
            logger.info "    --    exchange: #{route.exchange}"
            logger.info "    --       queue: #{route.queue}"
            logger.info "    -- routing_key: #{route.routing_key}"
            logger.info "    --    prefetch: #{route.prefetch}"
          end
        end
      end

      def start_subscribers!
        subscriptions.each do |subscription|
          route = subscription[:route]
          queue = subscription[:queue]
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
            run_env(env)
          end
          bunny_consumers << consumer
          queue.subscribe_with(consumer)
        end
      end

      def wait_to_finish_with_timeout(timeout)
        puts <<-MSG
          Currently bunny doesn't have any sort of a graceful shutdown or
          the ability to check on the status of its ConsumerWorkPool objects.
          For now we just wait for #{timeout}sec to let the worker pools drain.
        MSG
        sleep(timeout)
      end

      private

      def run_env(env)
        logger.info "RECEIVED #{env.message_id} from #{env.queue}"
        ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
          ::ActionSubscriber.config.middleware.call(env)
        end
      end
    end
  end
end
