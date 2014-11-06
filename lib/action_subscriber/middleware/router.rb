module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        subscriber = env.subscriber.new(env)
        action = subscriber.method(env.action)
        env.acknowledge if env.subscriber.acknowledge_messages_before_processing?

        begin
          action.call
        rescue
          env.reject if env.subscriber.acknowledge_messages_after_processing?
          raise $!
        ensure
          env.acknowledge if env.subscriber.acknowledge_messages_after_processing?
        end
      end
    end
  end
end
