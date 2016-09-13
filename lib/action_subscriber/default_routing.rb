module ActionSubscriber
  module DefaultRouting
    def routes
      @routes ||= begin
        routes = []
        exchange_names.each do |exchange_name|
          subscribable_methods.each do |method_name|
            routes << ActionSubscriber::Route.new({
              acknowledgements: acknowledge_messages?,
              action: method_name,
              connection: ::ActionSubscriber::RabbitConnection.subscriber_connection,
              durable: false, 
              exchange: exchange_name,
              routing_key: routing_key_name_for_method(method_name),
              subscriber: self,
              queue: queue_name_for_method(method_name),
            })
          end
        end
        routes
      end
    end
  end
end
