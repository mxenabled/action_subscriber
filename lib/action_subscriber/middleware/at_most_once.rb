module ActionSubscriber
  module Middleware
    class AtMostOnce
      def initialize(app)
        @app = app
      end

      def call(env)
        env.acknowledge
        @app.call(env)
      end
    end
  end
end
