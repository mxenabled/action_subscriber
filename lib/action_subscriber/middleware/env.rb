module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :content_type,
                  :encoded_payload,
                  :exchange,
                  :headers,
                  :message_id,
                  :routing_key,
                  :subscriber

      ##
      # @param subscriber [Class] the class that will handle this message
      # @param encoded_payload [String] the payload as it was received from RabbitMQ
      # @param properties [Hash] that must contain the following keys (as symbols)
      #         :channel => RabbitMQ channel for doing acknowledgement
      #         :content_type => String
      #         :delivery_tag => String (the message identifier to send back to rabbitmq for acknowledgement)
      #         :exchange => String
      #         :headers => Hash[ String => String ]
      #         :message_id => String
      #         :routing_key => String
      def initialize(subscriber, encoded_payload, properties)
        @channel = properties.fetch(:channel)
        @content_type = properties.fetch(:content_type)
        @delivery_tag = properties.fetch(:delivery_tag)
        @encoded_payload = encoded_payload
        @exchange = properties.fetch(:exchange)
        @headers = properties.fetch(:headers) || {}
        @message_id = properties.fetch(:message_id)
        @routing_key = properties.fetch(:routing_key)
        @subscriber = subscriber
      end

      def acknowledge
        acknowledge_multiple_messages = false
        @channel.ack(@delivery_tag, acknowledge_multiple_messages)
      end

      # Return the last element of the routing key to indicate which action
      # to route the payload to
      #
      def action
        routing_key.split('.').last.to_s
      end

      def reject
        requeue_message = true
        @channel.reject(@delivery_tag, requeue_message)
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
