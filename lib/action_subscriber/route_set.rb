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

    def print_middleware_stack
      ::ActionSubscriber.config.middleware.print_middleware_stack
    end

    def print_subscriptions
      print_middleware_stack
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
      finisher_threads = []

      ::ActionSubscriber::ThreadPools.threadpools.map do |name, threadpool|
        logger.info "  -- Threadpool #{name} (queued: #{threadpool.queue_length})"
        finisher_threads << ::Thread.new(threadpool, timeout, name) do |internal_pool, internal_timeout, internal_name|
          completed = internal_pool.wait_for_termination(internal_timeout)

          unless completed
            logger.error "  -- FAILED #{internal_name} did not finish shutting down within #{internal_timeout}sec"
          end
        end
      end

      finisher_threads.each(&:join)
    end

  private

    def subscriptions
      @subscriptions ||= []
    end

    def run_env(env, threadpool)
      logger.info "RECEIVED #{env.message_id} from #{env.queue}"
      threadpool << lambda do
        ::ActionSubscriber.config.middleware.call(env)
      end
    end
  end
end
