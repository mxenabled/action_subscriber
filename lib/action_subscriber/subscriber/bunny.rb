module ActionSubscriber
  module Subscriber
    module Bunny
      def setup_channel(route)
        channel = connection.create_channel
        channel.prefetch(route.prefetch) if route.acknowledge_messages?
        channel
      end

      def subscribe_to(route, queue)
        options = { :manual_ack => route.acknowledge_messages? }
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

          pool.async(env) do |env|
            ActionSubscriber.config.middleware.call(env)
          end
        end
      end
    end
  end
end
