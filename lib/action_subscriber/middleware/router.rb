module ActionSubscriber
  module Middleware
    class Router
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        logger.info "START #{env.message_id} #{env.subscriber}##{env.action}"
        env.subscriber.run_action_with_filters(env, env.action)
        logger.info "FINISHED #{env.message_id}"
      end
    end
  end
end
