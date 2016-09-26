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
            logger.error "WARNING having a prefetch lower than your concurrency will prevent your subscriber from fully utilizing its threadpool" if route.prefetch < route.concurrency
          end
        end
      end

      def print_threadpool_stats
        logger.info "*DISCLAIMER* the number of running jobs is just a best guess. We don't have a good way to introspect the bunny threadpools so jobs that are sleeping or waiting on IO won't show up as running"
        subscriptions.group_by{|subscription| subscription[:route].subscriber}.each do |subscriber, subscriptions|
          logger.info subscriber.name
          subscriptions.each do |subscription|
            route = subscription[:route]
            work_pool = subscription[:queue].channel.work_pool
            running_threads = work_pool.threads.select{|thread| thread.status == "run"}.count
            routes.each do |route|
              logger.info "  -- method: #{route.action}"
              logger.info "    --  concurrency: #{route.concurrency}"
              logger.info "    -- running jobs: #{running_threads}"
              logger.info "    --      backlog: #{work_pool.backlog}"
            end
          end
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

      def setup_queue(route)
        channel = ::ActionSubscriber::RabbitConnection.with_connection(route.connection_name){ |connection| connection.create_channel(nil, route.concurrency) }
        exchange = channel.topic(route.exchange)
        queue = channel.queue(route.queue, :durable => route.durable)
        queue.bind(exchange, :routing_key => route.routing_key)
        queue
      end
    end
  end
end
