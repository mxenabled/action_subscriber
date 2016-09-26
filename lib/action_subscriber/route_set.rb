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

  private

    def subscriptions
      @subscriptions ||= []
    end

    def run_env(env)
      logger.info "RECEIVED #{env.message_id} from #{env.queue}"
      ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
        ::ActionSubscriber.config.middleware.call(env)
      end
    end
  end
end
