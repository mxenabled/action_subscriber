module ActionSubscriber
  module Middleware
    class Base
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(subscriber)
        app.call(subscriber)
      end
    end
  end
end
