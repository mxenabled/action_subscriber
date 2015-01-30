module ActionSubscriber
  module Middleware
    class ErrorHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue => error
        ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
      end
    end
  end
end
