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
        if subscriber.respond_to?(env.action)
          action = subscriber.method(env.action)

          # TODO: Remove this check in 1.0
          if action.arity == 0
            action.call
          else
            warn 'DEPRECATED passing the payload to subscribable methods is deprecated and will be removed in Action Subscriber 1.0. Use the :payload attribute in the subscriber instead.'
            action.call(env.payload)
          end
        end

      # TODO: Extract error handling into a middleware
      #
      rescue => exception
        ::ActionSubscriber.configuration.error_handler.call(exception)
      end
    end
  end
end
