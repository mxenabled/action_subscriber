if defined?(Rails)
  require "action_subscriber/middleware/active_record/connection_management"
  require "action_subscriber/middleware/active_record/query_cache"
end

module ActionSubscriber
  module DefaultRouter
    def self.routes_for_class(klass)
      klass.exchange.map do |exchange|
        klass.subscribable_methods.map do |method_symbol|
          ActionSubscriber::Route.new(
            :action => method_symbol,
            :acknowledge_messages => klass.acknowledge_messages?,
            :exchange => exchange,
            :middleware_stack => self.middleware_stack_for_class(klass),
            :prefetch => ::ActionSubscriber.configuration.prefetch,
            :queue => klass.queue_name_for_method(method_symbol),
            :routing_key => klass.routing_key_name_for_method(method_symbol),
            :subscriber => klass,
          )
        end
      end.flatten
    end

    def self.middleware_stack_for_class(klass)
      ::Middleware::Builder.new(:runner_class => Middleware::Runner) do
        use Middleware::ErrorHandler
        use Middleware::Decoder
        if defined?(Rails)
          use Middleware::ActiveRecord::ConnectionManagement
          use Middleware::ActiveRecord::QueryCache
        end
        use Middleware::AtMostOnce if klass.acknowledge_messages? && klass.acknowledge_messages_before_processing?
        use Middleware::AtLeastOnce if klass.acknowledge_messages? && klass.acknowledge_messages_after_processing?
      end
    end
  end
end
