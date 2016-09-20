module ActionSubscriber
  module Middleware
    class ErrorHandler
      include ::ActionSubscriber::Logging

      def initialize(app)
        @app = app
      end

      def call(env)
        job_mutex = ::Mutex.new
        job_complete = ::ConditionVariable.new

        job_mutex.synchronize do
          ::Thread.new do
            begin
              @app.call(env)
            rescue => error
              logger.error "FAILED #{env.message_id}"
              ::ActionSubscriber.configuration.error_handler.call(error, env.to_h)
            ensure
              job_complete.signal
            end
          end

          job_complete.wait(job_mutex)
        end
      end
    end
  end
end
