module ActionSubscriber
  module Middleware
    class Base
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        app.call(env)
      end
    end
  end
end
