module ActionSubscriber
  class Railtie < ::Rails::Railtie
    config.action_subscriber = ::ActionSubscriber.config

    ::ActiveSupport.on_load(:active_record) do
      require "action_subscriber/middleware/active_record/connection_management_async"
      require "action_subscriber/middleware/active_record/connection_management"
      require "action_subscriber/middleware/active_record/query_cache"

      ::ActionSubscriber.config.middleware.use ::ActionSubscriber::Middleware::ActiveRecord::ConnectionManagementAsync
      ::ActionSubscriber.config.middleware.use ::ActionSubscriber::Middleware::ActiveRecord::QueryCache
    end
  end
end
