module ActionSubscriber
  module Middleware
    class ActiveRecordConnection
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(subscriber)
        ::ActiveRecord::Base.connection_pool.with_connection do
          app.call(subscriber)
        end
      end
    end
  end
end
