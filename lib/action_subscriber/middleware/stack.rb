require 'middleware/builder'

module ActionSubscriber
  module Middleware
    class Stack < ::Middleware::Builder
      def uses(*middlewares)
        middlewares.each{ |middleware_args| use(*middleware_args) }
      end

      #fork is better method name but fork is defined on object
      def forked
        forked_stack = self.class.new(:runner_class => @runner_class)
        forked_stack.uses(*@stack)
        forked_stack
      end
    end
  end
end
