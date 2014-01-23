module ActionSubscriber
  module Middleware
    class Router < Base
      def call(subscriber)
        subscriber.consume_event

        # app.call(subscriber) ?
      end
    end
  end
end
