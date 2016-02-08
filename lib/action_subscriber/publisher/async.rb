module ActionSubscriber
  module Publisher
    # Publish a message asynchronously to RabbitMQ.
    #
    # Asynchronous is designed to do two things:
    # 1. Introduce the idea of a durable retry should the RabbitMQ connection disconnect.
    # 2. Provide a higher-level pattern for fire-and-forget publishing.
    #
    # @param [String] route The routing key to use for this message.
    # @param [String] payload The message you are sending. Should already be encoded as a string.
    # @param [String] exchange The exchange you want to publish to.
    # @param [Hash] options hash to set message parameters (e.g. headers).
    def self.publish_async(route, payload, exchange_name, options = {})
      Async.publisher_adapter.publish(route, payload, exchange_name, options)
    end

    module Async
      def self.publisher_adapter
        @publisher_adapter ||= case ::ActionSubscriber.configuration.async_publisher
                               when /memory/i then
                                 require "action_subscriber/publisher/async/in_memory_adapter"
                                 InMemoryAdapter.new
                               when /redis/i then
                                 fail "Not yet implemented"
                               else
                                 fail "Unknown adapter '#{::ActionSubscriber.configuration.async_publisher}' provided"
                               end
      end
    end
  end
end
