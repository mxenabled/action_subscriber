module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        subscriber = env.subscriber.new(env)

#        env.acknowledge if env.subscriber.acknowledge_messages_before_processing?
        subscriber.public_send(env.action)
#        env.acknowledge if env.subscriber.acknowledge_messages_after_processing?
      end
    end
  end
end
