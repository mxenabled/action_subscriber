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
      # Make channels threadsafe again! Believe Me!
      # Accessing channels from multiple threads for messsage acknowledgement will crash
      # a channel and stop messages from being received on that channel
      # this isn't very clear in the documentation for march_hare/bunny, but it is
      # explicitly addresses here: https://github.com/rabbitmq/rabbitmq-java-client/issues/53
      channel = ::ActionSubscriber::Synchronizer.new(channel)
      exchange = channel.topic(route.exchange)
      queue = create_queue(channel, route.queue, :durable => route.durable)
      queue.bind(exchange, :routing_key => route.routing_key)
      queue
    end
  end
end
