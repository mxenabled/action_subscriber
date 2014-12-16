module ActionSubscriber
  module DefaultRouter
    def self.routes_for_class(klass)
      klass.exchange.map do |exchange|
        klass.subscribable_methods.map do |method_symbol|
          ActionSubscriber::Route.new(
            :action => method_symbol,
            :acknowledge_messages => klass.acknowledge_messages?,
            :exchange => exchange,
            :prefetch => ::ActionSubscriber.configuration.prefetch,
            :queue => klass.queue_name_for_method(method_symbol),
            :routing_key => klass.routing_key_name_for_method(method_symbol),
            :subscriber => klass,
          )
        end
      end.flatten
    end
  end
end
