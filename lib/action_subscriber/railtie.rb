module ActionSubscriber
  class Railtie < ::Rails::Railtie
    config.action_subscriber = ::ActionSubscriber.config

    ::ActiveSupport.on_load(:active_record) do
      require "action_subscriber/middleware/active_record/connection_management"
      require "action_subscriber/middleware/active_record/query_cache"

      ::ActionSubscriber.config.middleware.insert_after ::ActionSubscriber::Middleware::Decoder, ::ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement
      ::ActionSubscriber.config.middleware.insert_after ::ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement, ::ActionSubscriber::Middleware::ActiveRecord::QueryCache
    end
  end
end
