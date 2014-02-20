module ActionSubscriber
  module Middleware
    class Router
      def intialize(app)
        @app = app
      end

      def call(env)
        env.subscriber.consume_event
        env
      end
    end
  end
end
