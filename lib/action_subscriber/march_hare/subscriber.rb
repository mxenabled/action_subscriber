module ActionSubscriber
  module MarchHare
    module Subscriber
      include ::ActionSubscriber::Logging

      def cancel_consumers!
        march_hare_consumers.each(&:cancel)
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
            if route.acknowledgements != subscriber.acknowledge_messages?
              logger.error "WARNING subscriber has acknowledgements as #{subscriber.acknowledge_messages?} and route has acknowledgements as #{route.acknowledgements}"
            end
          end
        end
      end

      def print_threadpool_stats
        ::ActionSubscriber::RabbitConnection.connection_threadpools.each do |name, executor|
          logger.info "Connection #{name}"
          logger.info "  -- available threads: #{executor.get_maximum_pool_size}"
          logger.info "  --    running thread: #{executor.get_active_count}"
          logger.info "  --           backlog: #{executor.get_queue.size}"
        end
      end

      def setup_subscriptions!
        fail ::RuntimeError, "you cannot setup queues multiple times, this should only happen once at startup" unless subscriptions.empty?
        routes.each do |route|
          route.concurrency.times do
            subscriptions << {
              :route => route,
              :queue => setup_queue(route),
            }
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
            logger.info "  -- Connection #{name} (active: #{executor.get_active_count}, queued: #{executor.get_queue.size})"
            any_threadpools_busy = true
          end
          if !any_threadpools_busy
            logger.info "Connection threadpools empty"
            break
          end
          break if wait_loops >= timeout
          Thread.pass
          sleep 1
        end
      end

      private

      def setup_queue(route)
        channel = ::ActionSubscriber::RabbitConnection.with_connection(route.connection_name){ |connection| connection.create_channel }
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
