require "action_subscriber/middleware/decoder"
require "action_subscriber/middleware/env"
require "action_subscriber/middleware/error_handler"
require "action_subscriber/middleware/router"
require "action_subscriber/middleware/runner"

module ActionSubscriber
  module Middleware
    def self.initialize_stack
      builder = ::Middleware::Builder.new(:runner_class => ::ActionSubscriber::Middleware::Runner)

      builder.use ::ActionSubscriber::Middleware::ErrorHandler
      builder.use ::ActionSubscriber::Middleware::Decoder

      builder
    end
  end
end
