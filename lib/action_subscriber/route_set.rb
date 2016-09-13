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

    def setup_subscriptions!
      fail ::RuntimeError, "you cannot setup queues multiple times, this should only happen once at startup" unless subscriptions.empty?
      routes.each do |route|
        route.concurrency.times do
          subscriptions << {
            :route => route,
            :queue => setup_queue(route),
          }
        end
      end
    end

  private

    def subscriptions
      @subscriptions ||= []
    end

    def setup_queue(route)
      channel = ::ActionSubscriber::RabbitConnection.with_connection{ |connection| connection.create_channel }
      exchange = channel.topic(route.exchange)
      # TODO go to back to the old way of creating a queue?
      queue = create_queue(channel, route.queue, :durable => route.durable)
      queue.bind(exchange, :routing_key => route.routing_key)
      queue
    end
  end
end
