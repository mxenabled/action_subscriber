require "action_subscriber/logging"
require "action_subscriber/middleware/decoder"
require "action_subscriber/middleware/env"
require "action_subscriber/middleware/error_handler"
require "action_subscriber/middleware/resubscribe_env"
require "action_subscriber/middleware/resubscribe_handler"
require "action_subscriber/middleware/router"
require "action_subscriber/middleware/runner"

module ActionSubscriber
  module Middleware

    class Builder < ::Middleware::Builder
      include ::ActionSubscriber::Logging

      def print_middleware_stack
        logger.info "Middlewares ["

        stack.each do |middleware|
          logger.info "#{middleware}"
        end

        logger.info "]"
      end
    end

    def self.initialize_stack
      builder = ::ActionSubscriber::Middleware::Builder.new(:runner_class => ::ActionSubscriber::Middleware::Runner)

      builder.use ::ActionSubscriber::Middleware::ErrorHandler
      builder.use ::ActionSubscriber::Middleware::Decoder

      builder
    end

    def self.initialize_resubscribe_stack
      builder = ::ActionSubscriber::Middleware::Builder.new
      builder.use ::ActionSubscriber::Middleware::ResubscribeHandler

      builder
    end
  end
end
