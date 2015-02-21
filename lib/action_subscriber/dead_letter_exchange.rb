module ActionSubscriber
  module DeadLetterExchange
    def self.setup_retries_queue
      channel = ::ActionSubscriber::RabbitConnection.connection.create_channel
      exchange = channel.topic("retries")
      queue = channel.queue("timeout", :arguments => {"x-dead-letter-exchange" => "events"})
      queue.bind(exchange, :routing_key => "#")
    end

    def self.requeue_with_backoff(env)
      puts "going to requeue #{env.payload}"
      channel = ::ActionSubscriber::RabbitConnection.connection.create_channel
      channel.confirm_select
      publish_message_with_ttl(env, channel)
      success = channel.wait_for_confirms
      raise "WAT! Failed to publish retry message! #{success}" unless success
    end

    def self.publish_message_with_ttl(env, channel)
      exchange = channel.topic("retries")
      ttl = next_ttl(env)
      puts "ttl = #{ttl}"
      if ttl
        exchange.publish(env.encoded_payload, :content_type => env.content_type, :expiration => ttl, :routing_key => env.routing_key)
      end
    end

    def self.next_ttl(env)
      headers = env.headers || {}
      death = headers.fetch("x-death", [{"original-expiration" => 100}]).first
      next_ttl = death["original-expiration"].to_i * 3
      return false if next_ttl > 86_400
      next_ttl
    end
  end
end
