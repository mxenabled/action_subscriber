module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        env.acknowledge if env.subscriber.acknowledge_messages_before_processing?
        env.subscriber.run_action_with_filters(env, env.action)
        env.acknowledge if env.subscriber.acknowledge_messages_after_processing?
      end
    end
  end
end
