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

    def self.redeliver_message_with_backoff(env, backoff_schedule = SCHEDULE)
      next_attempt = get_last_attempt_number(env) + 1
      ttl = backoff_schedule[next_attempt]
      return unless ttl
      retry_queue_name = "#{env.queue}.retry_#{ttl}"
      with_exchange(env, ttl, retry_queue_name) do |exchange|
        exchange.publish(env.encoded_payload, retry_options(env, next_attempt, retry_queue_name))
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
      end.merge({
        "as-attempt" => attempt.to_s,
        "x-dead-letter-routing-key" => env.queue,
      })
    end

    def self.retry_options(env, attempt, retry_queue_name)
      {
        :content_type => env.content_type,
        :routing_key => retry_queue_name,
        :headers => retry_headers(env, attempt),
      }
    end

    def self.with_exchange(env, ttl, retry_queue_name)
      channel = env.channel
      begin
        channel.confirm_select
        # an empty string is the default exchange [see bunny docs](http://rubybunny.info/articles/exchanges.html#default_exchange)
        exchange = channel.topic("")
        queue = channel.queue(retry_queue_name, :arguments => {"x-dead-letter-exchange" => "", "x-message-ttl" => ttl, "x-dead-letter-routing-key" => env.queue})
        yield(exchange)
        channel.wait_for_confirms
      end
    end
  end
end
