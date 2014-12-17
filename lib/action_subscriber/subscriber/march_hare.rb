module ActionSubscriber
  module Subscriber
    module MarchHare
      def subscribe_to(route, queue)
        options = { :manual_ack => route.acknowledge_messages? }
        queue.subscribe(options) do |header, encoded_payload|
          properties = {
            :channel => queue.channel,
            :content_type => header.content_type,
            :delivery_tag => header.delivery_tag,
            :exchange => header.exchange,
            :message_id => header.message_id,
            :routing_key => header.routing_key,
          }

          env = Middleware::Env.new(route.subscriber, encoded_payload, properties)

          Threadpool.pool.async(env) do |env|
            ActionSubscriber.config.middleware.call(env)
          end
        end
      end
    end
  end
end
