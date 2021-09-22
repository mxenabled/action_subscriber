module ActionSubscriber
  module Middleware
    class ResubscribeHandler
      attr_reader :env
      delegate :consumer, :consumers, :route_set, :subscription, :to => :env

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        route = subscription[:route]
        queue = subscription[:queue]

        ::ActionSubscriber.logger.warn "Cancellation received for queue consumer: #{queue.name}, rebuilding subscription..."
        consumers.delete(consumer)
        queue.channel.close
        subscription[:queue] = route_set.setup_queue(route)
        route_set.start_subscriber_for_subscription(subscription)

        @app.call(env)
      end
    end
  end
end
