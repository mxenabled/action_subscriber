module ActionSubscriber
  module Middleware
    class ActiveRecordConnection < Base
      def call(env)
        ::ActiveRecord::Base.connection_pool.with_connection do
          app.call(env)
        end
      end
    end
  end
end
