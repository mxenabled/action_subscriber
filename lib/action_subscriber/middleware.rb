require "action_subscriber/middleware/decoder"
require "action_subscriber/middleware/env"
require "action_subscriber/middleware/error_handler"
require "action_subscriber/middleware/router"

module ActionSubscriber
  module Middleware
    def self.initialize_stack
      builder = ::Middleware::Builder.new do
        use ErrorHandler
        use Decoder
        use Router
      end
    end
  end
end
