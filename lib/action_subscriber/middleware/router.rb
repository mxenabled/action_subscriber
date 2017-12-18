module ActionSubscriber
  module Middleware
    class Router
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        logger.info { "START #{env.message_id} #{env.subscriber}##{env.action}" }
        ::ActiveSupport::Notifications.instrument "process_event.action_subscriber", :subscriber => env.subscriber.to_s, :routing_key => env.routing_key, :queue => env.queue do
          env.subscriber.run_action_with_filters(env, env.action)
        end
        logger.info { "FINISHED #{env.message_id}" }
      end
    end
  end
end
