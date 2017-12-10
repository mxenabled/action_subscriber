module ActionSubscriber
  class RouteSet
    if ::RUBY_PLATFORM == "java"
      include ::ActionSubscriber::MarchHare::Subscriber
    else
      include ::ActionSubscriber::Bunny::Subscriber
    end

    attr_reader :routes

    def initialize(routes)
      @routes = routes
    end

    def print_subscriptions
      routes.group_by(&:subscriber).each do |subscriber, routes|
        logger.info subscriber.name
        routes.each do |route|
          threadpool = ::ActionSubscriber::ThreadPools.threadpools[route.threadpool_name]
          logger.info "  -- method: #{route.action}"
          logger.info "    --  threadpool: #{route.threadpool_name} (#{threadpool.max_length} threads)"
          logger.info "    --    exchange: #{route.exchange}"
          logger.info "    --       queue: #{route.queue}"
          logger.info "    -- routing_key: #{route.routing_key}"
          logger.info "    --    prefetch: #{route.prefetch}"
          if subscriber.at_most_once? && (route.prefetch < subscriber.ack_every_n_messages || subscriber.ack_every_n_messages <= 0)
            # https://www.rabbitmq.com/blog/2011/09/24/sizing-your-rabbits/
            logger.error "ERROR Subscriber has ack_every_n_messages as #{subscriber.ack_every_n_messages} and route has prefetch as #{route.prefetch}"
            fail "prefetch < ack_every_n_messages, deadlock will occur"
          end
          if route.acknowledgements != subscriber.acknowledge_messages?
            logger.error "WARNING subscriber has acknowledgements as #{subscriber.acknowledge_messages?} and route has acknowledgements as #{route.acknowledgements}"
          end
        end
      end
    end

    def print_threadpool_stats
      ::ActionSubscriber::ThreadPools.threadpools.each do |name, threadpool|
        logger.info "Threadpool #{name}"
        logger.info "  -- available threads: #{threadpool.length}"
        logger.info "  --           backlog: #{threadpool.queue_length}"
      end
    end

    def wait_to_finish_with_timeout(timeout)
      ::ActionSubscriber::ThreadPools.threadpools.map do |name, threadpool|
        logger.info "  -- Threadpool #{name} (queued: #{threadpool.queue_length})"
        ::Thread.new do
          completed = threadpool.wait_for_termination(timeout)
          unless completed
            logger.error "  -- FAILED #{name} did not finish shutting down within #{timeout}sec"
          end
        end
      end.each(&:join)
    end

  private

    def subscriptions
      @subscriptions ||= []
    end

    def run_env(env, threadpool)
      logger.info "RECEIVED #{env.message_id} from #{env.queue}"
      ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
        threadpool << lambda do
          ::ActionSubscriber.config.middleware.call(env)
        end
      end
    end
  end
end
