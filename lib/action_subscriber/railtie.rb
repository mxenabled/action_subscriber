module ActionSubscriber
  class Railtie < ::Rails::Railtie
    config.action_subscriber = ::ActionSubscriber.config

    # This hook happens after `Rails::Application` is inherited within
    # config/application.rb and before config is touched, usually within the
    # class block. Definitely before config/environments/*.rb and
    # config/initializers/*.rb.
    config.before_configuration do
      if ::Rails::VERSION::MAJOR < 5 && defined?(::ActiveRecord)
        require "action_subscriber/middleware/active_record/connection_management"
        require "action_subscriber/middleware/active_record/query_cache"

        ::ActionSubscriber.config.middleware.insert_after ::ActionSubscriber::Middleware::Decoder, ::ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement
        ::ActionSubscriber.config.middleware.insert_after ::ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement, ::ActionSubscriber::Middleware::ActiveRecord::QueryCache
      end
    end

    # This hook happens after all initializers are run, just before returning
    # from config/environment.rb back to cli.
    config.after_initialize do
      if ::Rails::VERSION::MAJOR >= 5
        require "action_subscriber/middelware/rails/reloader"

        ::ActionSubscriber.config.middleware.insert_after ::ActionSubscriber::Middleware::Decoder, ::ActionSubscriber::Middleware::Rails::Reloader
      end
    end
  end
end
