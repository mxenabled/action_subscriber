module ActionSubscriber
  class SubscriptionSet
    attr_reader :connection, :routes

    def initialize(routes)
      @connection = ActionSubscriber::RabbitConnection.new_connection
      @routes = routes
    end

    def start
      routes.each do |route|
        channel = setup_channel(route)
        queue = setup_queue(route, channel)
        options = subscription_options(route)

        queue.subscribe(options) do |delivery_info, properties, encoded_payload|
          properties = {
            :channel => queue.channel,
            :content_type => properties.content_type,
            :delivery_tag => delivery_info.delivery_tag,
            :exchange => delivery_info.exchange,
            :message_id => properties.message_id,
            :routing_key => delivery_info.routing_key,
          }
          env = Middleware::Env.new(route.subscriber, encoded_payload, properties)

          Threadpool.pool.async(env) do |env|
            ActionSubscriber.config.middleware.call(env)
          end
        end
      end
    end

    def stop
      connection.close
    end

  private

    def setup_channel(route)
      channel = connection.channel
      channel.prefetch(route.prefetch) if route.acknowledge_messages?
      channel
    end

    def setup_queue(route, channel)
      exchange = channel.topic(route.exchange)
      queue = channel.queue(route.queue)
      queue.bind(exchange, :routing_key => route.routing_key)
      queue
    end

    def subscription_options(route)
      { :manual_ack => route.acknowledge_messages? }
    end
  end
end
