module ActionSubscriber
  module Middleware
    class ErrorHandler
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue Exception => error # make sure we capture any exception from the top of the hierarchy
        logger.error { "FAILED #{env.message_id}" }

        # There is more to this rescue than meets the eye. MarchHare's java library will rescue errors
        # and attempt to close the channel with its default exception handler. To avoid this, we will
        # stop errors right here. If you want to handle errors, you must do it in the error handler and
        # it should not re-raise. As a bonus, not killing these threads is better for your runtime :).
        begin
          ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
        rescue Exception => inner_error
          logger.error { "ActionSubscriber error handler raised error, but should never raise. Error: #{inner_error}" }
        end
      ensure
        # This second rescue is a little extreme, but we need to be very cautious here to avoid errors
        # being sent back to bunny or march_hare land.
        begin
          # Make sure we attempt to `nack` a message that did not get processed if something fails
          env.safe_nack
        rescue Exception => inner_error
          logger.error { "ActionSubscriber error handler raised error while nack-ing message. Error: #{inner_error}" }
        end
      end
    end
  end
end
