module ActionSubscriber
  module Middleware
    class ActiveRecordConnection < Base
      def call(subscriber)
        ::ActiveRecord::Base.connection_pool.with_connection do
          app.call(subscriber)
        end
      end
    end
  end
end
