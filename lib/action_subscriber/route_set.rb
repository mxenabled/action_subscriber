module ActionSubscriber
  class RouteSet
    if ::RUBY_PLATFORM == "java"
      include ::ActionSubscriber::MarchHare::Subscriber
    else
      include ::ActionSubscriber::Bunny::Subscriber
    end

    attr_reader :routes

    def initialize(routes)
      @routes = routes
    end

    def setup_queues!
      routes.each do |route|
        queues[route] = setup_queue(route)
      end
    end

  private

    def queues
      @queues ||= {}
    end

    def setup_queue(route)
      channel = ::ActionSubscriber::RabbitConnection.subscriber_connection.create_channel
      exchange = channel.topic(route.exchange, :durable => route.durable)
      queue = channel.queue(route.queue, :durable => route.durable)
      queue.bind(exchange, :routing_key => route.routing_key)
      queue
    end
  end
end
