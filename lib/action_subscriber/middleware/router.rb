module ActionSubscriber
  module Middleware
    class Router < Base
      def call(subscriber)
        subscriber.consume_event
      end
    end
  end
end
