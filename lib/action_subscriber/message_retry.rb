module ActionSubscriber
  module MessageRetry
    def self.redeliver_message_with_backoff(env)
      ttl = calculate_ttl(env)
      return unless ttl
      with_exchange(env, ttl) do |exchange|
        exchange.publish(env.encoded_payload,
          :content_type => env.content_type,
          :routing_key => env.routing_key,
          :expiration => ttl
        )
      end
    end

    # Private Implementation
    def self.calculate_ttl(env)
      death = env.headers.fetch("x-death", [{"original-expiration" => "20"}]).first
      next_ttl = death["original-expiration"].to_s.to_i * 5
      return false if next_ttl > 86_400_000
      next_ttl
    end

    def self.with_exchange(env, ttl)
      retry_name = "#{env.exchange}_retry_#{ttl}"
      channel = RabbitConnection.subscriber_connection.create_channel
      begin
        channel.confirm_select
        exchange = channel.topic(retry_name)
        queue = channel.queue(retry_name, :arguments => {"x-dead-letter-exchange" => env.exchange})
        queue.bind(exchange, :routing_key => "#")
        yield(exchange)
        channel.wait_for_confirms
      ensure
        channel.close rescue nil
      end
    end
  end
end
