require 'middleware/builder'

module ActionSubscriber
  module Middleware
    class Stack < ::Middleware::Builder
      def forked
        forked_stack = self.class.new(:runner_class => @runner_class)

        @stack.each do |middleware_args|
          forked_stack.use(middleware_args.first)
        end

        forked_stack
      end
    end
  end
end
