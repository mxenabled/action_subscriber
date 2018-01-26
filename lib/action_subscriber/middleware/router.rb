module ActionSubscriber
  module Middleware
    class Router
      INSTRUMENT_KEY = "process_event.action_subscriber".freeze
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        action = env.action
        message_id = env.message_id
        queue = env.queue
        routing_key = env.routing_key
        subscriber = env.subscriber

        logger.info { "START #{message_id} #{subscriber}##{action}" }

        instrument_call(subscriber, routing_key, queue) do
          subscriber.run_action_with_filters(env, action)
        end

        logger.info { "FINISHED #{message_id}" }
      end

    private

      def instrument_call(subscriber, routing_key, queue)
        ::ActiveSupport::Notifications.instrument INSTRUMENT_KEY, :subscriber => subscriber.to_s, :routing_key => routing_key, :queue => queue do
          yield
        end
      end
    end
  end
end
