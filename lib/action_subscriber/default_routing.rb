module ActionSubscriber
  module DefaultRouting
    def routes(route_settings)
      @routes ||= begin
        routes = []
        exchange_names.each do |exchange_name|
          subscribable_methods.each do |method_name|
            settings = {
              acknowledgements: acknowledge_messages?,
              action: method_name,
              durable: false,
              exchange: exchange_name,
              routing_key: routing_key_name_for_method(method_name),
              subscriber: self,
              queue: queue_name_for_method(method_name),
            }
            settings.merge!(route_settings)
            routes << ActionSubscriber::Route.new(settings)
          end
        end
        routes
      end
    end
  end
end
