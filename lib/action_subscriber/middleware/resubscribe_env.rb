module ActionSubscriber
  module Middleware
    class ResubscribeEnv
      attr_reader :consumer,
                  :consumers,
                  :route_set,
                  :subscription

      def initialize(properties)
        @consumer = properties.fetch(:consumer)
        @consumers = properties.fetch(:consumers)
        @route_set = properties.fetch(:route_set)
        @subscription = properties.fetch(:subscription)
      end
    end
  end
end
