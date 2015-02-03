module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        env.subscriber.run_action_with_filters(env, env.action)
      end
    end
  end
end
