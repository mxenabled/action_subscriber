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

        # There is more to this rescue than meets the eye. MarchHare's java library will rescue errors
        # and attempt to close the channel with its default exception handler. To avoid this, we will
        # stop errors right here. If you want to handle errors, you must do it in the error handler and
        # it should not re-raise. As a bonus, not killing these threads is better for your runtime :).
        begin
          ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
        rescue => error
          logger.error "ActionSubscriber error handler raised error, but should never raise. Error: #{error}"
        end
      end
    end
  end
end
