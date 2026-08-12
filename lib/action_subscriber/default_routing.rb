module ActionSubscriber
  module DefaultRouting
    def routes(route_settings)
      @routes ||= begin
        routes = []
        exchange_names.each do |exchange_name|
          subscribable_methods.each do |method_name|
            # No :durable key -- Route falls back to config.durable when it is absent,
            # and passing false here would override the global setting.
            settings = {
              acknowledgements: acknowledge_messages?,
              action: method_name,
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
