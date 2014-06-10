module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :acknowledger,
                  :content_type,
                  :encoded_payload,
                  :exchange,
                  :message_id,
                  :routing_key,
                  :subscriber

      ##
      # @param subscriber [Class] the class that will handle this message
      # @param encoded_payload [String] the payload as it was received from RabbitMQ
      # @param properties [Hash] that must contain the following keys (as symbols)
      #                   :acknowledger => Object (will be used to ack or reject a message when using manual acknowledgment)
      #                   :content_type => String
      #                   :exchange => String
      #                   :message_id => String
      #                   :routing_key => String
      
      def initialize(subscriber, encoded_payload, properties)
        @acknowledger = properties.fetch(:acknowledger)
        @content_type = properties.fetch(:content_type)
        @encoded_payload = encoded_payload
        @exchange = properties.fetch(:exchange)
        @message_id = properties.fetch(:message_id)
        @routing_key = properties.fetch(:routing_key)
        @subscriber = subscriber
      end

      # Return the last element of the routing key to indicate which action
      # to route the payload to
      #
      def action
        routing_key.split('.').last.to_s
      end

      def to_hash
        {
          :action => action,
          :content_type => content_type,
          :exchange => exchange,
          :routing_key => routing_key,
          :payload => payload
        }
      end
      alias_method :to_h, :to_hash

    end
  end
end
