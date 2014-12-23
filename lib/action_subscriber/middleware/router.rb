module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        subscriber = env.subscriber.new(env)

        subscriber.public_send(env.action)
      end
    end
  end
end
