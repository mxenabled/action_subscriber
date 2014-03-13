module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(subscriber)
        subscriber.consume_event
      end
    end
  end
end
