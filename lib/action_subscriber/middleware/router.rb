module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        subscriber = env.subscriber.new(env)
        action = subscriber.method(env.action)
        action.call
      end
    end
  end
end
