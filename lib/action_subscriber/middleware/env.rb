require "securerandom"

module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :action,
                  :content_type,
                  :delivery_tag,
                  :encoded_payload,
                  :exchange,
                  :headers,
                  :message_id,
                  :routing_key,
                  :queue,
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
        @action = properties.fetch(:action)
        @channel = properties[:channel]
        @content_type = properties.fetch(:content_type)
        @delivery_tag = properties.fetch(:delivery_tag)
        @encoded_payload = encoded_payload
        @exchange = properties.fetch(:exchange)
        @headers = properties.fetch(:headers) || {}
        @message_id = properties.fetch(:message_id) || ::SecureRandom.hex(3)
        @queue = properties.fetch(:queue)
        @routing_key = properties.fetch(:routing_key)
        @subscriber = subscriber
      end

      def acknowledge(acknowledge_multiple_messages = nil)
        fail ::RuntimeError, "you can't acknowledge messages under the polling API" unless @channel
        acknowledge_multiple_messages = false if acknowledge_multiple_messages.nil?
        @channel.ack(@delivery_tag, acknowledge_multiple_messages)
        true
      end

      def reject
        fail ::RuntimeError, "you can't acknowledge messages under the polling API" unless @channel
        requeue_message = true
        @channel.reject(@delivery_tag, requeue_message)
        true
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
