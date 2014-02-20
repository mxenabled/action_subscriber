module ActionSubscriber
  module Middleware
    class Router < Base
      def call(env)
        env.subscriber.consume_event
      end
    end
  end
end
