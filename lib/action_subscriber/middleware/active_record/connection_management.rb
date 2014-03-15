module ActionSubscriber
  module Middleware
    module ActiveRecord
      class ConnectionManagement
        def initialize(app)
          @app = app
        end

        def call(env)
          @app.call(env)
        ensure
          ::ActiveRecord::Base.clear_active_connections!
        end
      end
    end
  end
end
