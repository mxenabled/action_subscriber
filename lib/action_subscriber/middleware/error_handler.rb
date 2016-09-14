module ActionSubscriber
  module Middleware
    class ErrorHandler
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        # This insulates the connection thread from errors that are raised by the error_handle or
        # exceptions that don't fall under StandardError (which are not caught by `rescue => error`)
        new_thread = ::Thread.new do
          begin
            @app.call(env)
          rescue => error
            logger.error "FAILED #{env.message_id}"
            ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
          end
        end
        ::Thread.pass while new_thread.alive?
      end
    end
  end
end
