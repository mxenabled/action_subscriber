module ActionSubscriber
  module Middleware
    module ActiveRecord
      class QueryCache
        CURRENT_CONNECTION = "_action_subscriber_query_cache_current_connection".freeze

        def initialize(app)
          @app = app
        end

        def call(env)
          connection = ::Thread.current[CURRENT_CONNECTION] = ::ActiveRecord::Base.connection
          enabled = connection.query_cache_enabled
          connection.enable_query_cache!

          @app.call(env)
        ensure
          restore_query_cache_settings(enabled)
        end

        private

        def restore_query_cache_settings(enabled)
          ::Thread.current[CURRENT_CONNECTION].clear_query_cache
          ::Thread.current[CURRENT_CONNECTION].disable_query_cache! unless enabled
          ::Thread.current[CURRENT_CONNECTION] = nil
        end
      end
    end
  end
end
