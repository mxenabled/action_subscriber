module ActionSubscriber
  module Middleware
    class ErrorHandler
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue => error
        logger.error "FAILED #{env.message_id}"
        ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
      end
    end
  end
end
