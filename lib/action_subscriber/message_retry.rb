module ActionSubscriber
  module MessageRetry
    SCHEDULE = {
      2  =>        100,
      3  =>        500,
      4  =>      2_500,
      5  =>     12_500,
      6  =>     62_500,
      7  =>    312_500,
      8  =>  1_562_500,
      9  =>  7_812_500,
      10 => 39_062_500,
    }.freeze

    def self.redeliver_message_with_backoff(env)
      next_attempt = get_last_attempt_number(env) + 1
      ttl = SCHEDULE[next_attempt]
      return unless ttl
      with_exchange(env, ttl) do |exchange|
        exchange.publish(env.encoded_payload, retry_options(env, next_attempt))
      end
    end

    # Private Implementation
    def self.get_last_attempt_number(env)
      attempt_header = env.headers.fetch("as-attempt", "1")
      attempt_header.to_i
    end

    def self.retry_headers(env, attempt)
      env.headers.reject do |key, val|
        key == "x-death"
      end.merge({"as-attempt" => attempt.to_s})
    end

    def self.retry_options(env, attempt)
      {
        :content_type => env.content_type,
        :routing_key => env.routing_key,
        :headers => retry_headers(env, attempt),
      }
    end

    def self.with_exchange(env, ttl)
      exchange_retry_name = "#{env.exchange}_retry_#{ttl}"
      queue_retry_name = "#{env.queue}_retry_#{ttl}"
      channel = RabbitConnection.subscriber_connection.create_channel
      begin
        channel.confirm_select
        exchange = channel.topic(exchange_retry_name)
        queue = channel.queue(queue_retry_name, :arguments => {"x-dead-letter-exchange" => env.exchange, "x-message-ttl" => ttl})
        queue.bind(exchange, :routing_key => env.routing_key)
        yield(exchange)
        channel.wait_for_confirms
      ensure
        channel.close rescue nil
      end
    end
  end
end
