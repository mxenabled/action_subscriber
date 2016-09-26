module ActionSubscriber
  module MarchHare
    module Subscriber
      include ::ActionSubscriber::Logging

      def cancel_consumers!
        march_hare_consumers.each(&:cancel)
      end

      def create_queue(channel, queue_name, queue_options)
        queue = ::MarchHare::Queue.new(channel, queue_name, queue_options)
        queue.declare!
        queue
      end

      def march_hare_consumers
        @march_hare_consumers ||= []
      end

      def print_subscriptions
        routes.group_by(&:subscriber).each do |subscriber, routes|
          logger.info subscriber.name
          routes.each do |route|
            executor = ::ActionSubscriber::RabbitConnection.connection_threadpools[route.connection_name]
            logger.info "  -- method: #{route.action}"
            logger.info "    --  connection: #{route.connection_name} (#{executor.get_maximum_pool_size} threads)"
            logger.info "    -- concurrency: #{route.concurrency}"
            logger.info "    --    exchange: #{route.exchange}"
            logger.info "    --       queue: #{route.queue}"
            logger.info "    -- routing_key: #{route.routing_key}"
            logger.info "    --    prefetch: #{route.prefetch} per consumer (#{route.prefetch * route.concurrency} total)"
          end
        end
      end

      def start_subscribers!
        subscriptions.each do |subscription|
          route = subscription[:route]
          queue = subscription[:queue]
          queue.channel.prefetch = route.prefetch if route.acknowledgements?
          consumer = queue.subscribe(route.queue_subscription_options) do |metadata, encoded_payload|
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
            }
            env = ::ActionSubscriber::Middleware::Env.new(route.subscriber, encoded_payload, properties)
            run_env(env)
          end

          march_hare_consumers << consumer
        end
      end

      def wait_to_finish_with_timeout(timeout)
        wait_loops = 0
        loop do
          wait_loops = wait_loops + 1
          any_threadpools_busy = false
          ::ActionSubscriber::RabbitConnection.connection_threadpools.each do |name, executor|
            next if executor.get_active_count <= 0
            puts "  -- Connection #{name} (remaining: #{executor.get_active_count})"
            any_threadpools_busy = true
          end
          if !any_threadpools_busy
            puts "Connection threadpools empty"
            break
          end
          break if wait_loops >= timeout
          Thread.pass
          sleep 1
        end
      end

      private

      def run_env(env)
        logger.info "RECEIVED #{env.message_id} from #{env.queue}"
        ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
          ::ActionSubscriber.config.middleware.call(env)
        end
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
