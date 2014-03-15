module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        env.subscriber.consume_event
      end
    end
  end
end
