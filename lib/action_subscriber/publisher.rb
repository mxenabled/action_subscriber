module ActionSubscriber
  module Publisher
    # Publish a message to RabbitMQ
    #
    # @param [String] route The routing key to use for this message.
    # @param [String] payload The message you are sending. Should already be encoded as a string.
    # @param [String] exchange The exchange you want to publish to.
    # @param [Hash] options hash to set message parameters (e.g. headers)
    def self.publish(route, payload, exchange_name, options = {})
      with_exchange(exchange_name) do |exchange|
        exchange.publish(payload, publishing_options(route, options))
      end
    end

    def self.with_exchange(exchange_name)
      connection = RabbitConnection.publisher_connection
      channel = connection.create_channel
      begin
        channel.confirm_select if ActionSubscriber.configuration.publisher_confirms
        exchange = channel.topic(exchange_name)
        yield(exchange)
        channel.wait_for_confirms if ActionSubscriber.configuration.publisher_confirms
      ensure
        channel.close rescue nil
      end
    end

    def self.publishing_options(route, in_options = {})
      options = {
        :mandatory => false,
        :persistent => false,
        :routing_key => route,
      }.merge(in_options)

      if ::RUBY_PLATFORM == "java"
        java_options = {}
        java_options[:mandatory]   = options.delete(:mandatory)
        java_options[:routing_key] = options.delete(:routing_key)
        java_options[:properties]  = options
        java_options
      else
        options
      end
    end
  end
end
