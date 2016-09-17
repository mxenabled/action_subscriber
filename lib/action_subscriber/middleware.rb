require "action_subscriber/middleware/decoder"
require "action_subscriber/middleware/env"
require "action_subscriber/middleware/error_handler"
require "action_subscriber/middleware/router"
require "action_subscriber/middleware/runner"
require "action_subscriber/middleware/stack"

module ActionSubscriber
  module Middleware
    def self.initialize_stack
      builder = ::ActionSubscriber::Middleware::Stack.new(:runner_class => ::ActionSubscriber::Middleware::Runner)

      builder.use ErrorHandler
      builder.use Decoder

      builder
    end
  end
end
