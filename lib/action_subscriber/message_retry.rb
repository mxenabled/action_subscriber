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
      last_ttl = get_last_ttl_or_default(env.headers["x-death"], 20)
      next_ttl = last_ttl * 5
      return false if next_ttl > 86_400_000
      next_ttl
    end

    def self.get_last_ttl_or_default(x_death, default)
      return default unless x_death
      x_death = parse_x_death(x_death) if x_death.is_a?(String)
      x_death.map{|death| death["original-expiration"].to_i}.max
    end

    def self.parse_x_death(x_death)
      x_death.scan(/\{([^}]+)\}/).map(&:first).map do |str|
        str.scan(/([a-z\-]+)=([0-9a-z\-_.]+)/).to_h
      end
    end

    def self.with_exchange(env, ttl)
      exchange_retry_name = "#{env.exchange}_retry_#{ttl}"
      queue_retry_name = "#{env.queue}_retry_#{ttl}"
      channel = RabbitConnection.subscriber_connection.create_channel
      begin
        channel.confirm_select
        exchange = channel.topic(exchange_retry_name)
        queue = channel.queue(queue_retry_name, :arguments => {"x-dead-letter-exchange" => env.exchange})
        queue.bind(exchange, :routing_key => env.routing_key)
        yield(exchange)
        channel.wait_for_confirms
      ensure
        channel.close rescue nil
      end
    end
  end
end
