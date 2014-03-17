module ActionSubscriber
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        subscriber = env.subscriber.new(env)

        # TODO: Figure out if we should be checking this
        #
        subscriber.__send__(env.action) if subscriber.respond_to?(env.action)

      # TODO: Extract error handling into a middleware
      #
      rescue => exception
        ::ActionSubscriber.configuration.error_handler.call(exception)
      end
    end
  end
end
