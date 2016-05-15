require 'middleware/builder'

module ActionSubscriber
  module Middleware
    class Stack < ::Middleware::Builder
      def forked
        forked_stack = self.class.new(:runner_class => @runner_class)
        forked_stack.instance_variable_set(:@stack, @stack.deep_dup)
        forked_stack
      end
    end
  end
end
