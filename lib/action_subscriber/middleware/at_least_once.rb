module ActionSubscriber
  module Middleware
    class AtLeastOnce
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
        env.acknowledge
      rescue => error
        env.reject
        raise error
      end
    end
  end
end
