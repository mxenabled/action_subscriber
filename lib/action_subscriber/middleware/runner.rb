require 'middleware/runner'

module ActionSubscriber
  module Middleware
    class Runner < ::Middleware::Runner
      # Override the default middleware runner so we can ensure that the
      # router is the last thing called in the stack.
      #
      def initialize(stack)
        stack << ::ActionSubscriber::Middleware::Router

        super(stack)
      end
    end
  end
end
