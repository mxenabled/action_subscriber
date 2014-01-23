require "action_subscriber/middleware/base"
require "action_subscriber/middleware/router"

::ActiveSupport.on_load(:active_record) do
  require "action_subscriber/middleware/active_record_connection"

  ::ActionSubscriber.config.middleware.insert_before ::ActionSubscriber::Middleware::Router, ::ActionSubscriber::Middleware::ActiveRecordConnection
end
