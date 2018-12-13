require "securerandom"

module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :action,
                  :channel,
                  :content_type,
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
        @has_been_acked = false
        @has_been_nacked = false
        @has_been_rejected = false
        @headers = properties.fetch(:headers, {})
        @message_id = properties[:message_id].presence || ::SecureRandom.hex(3)
        @queue = properties.fetch(:queue)
        @routing_key = properties.fetch(:routing_key)
        @subscriber = subscriber
        @uses_acknowledgements = properties.fetch(:uses_acknowledgements, false)
      end

      def acknowledge
        fail ::RuntimeError, "you can't acknowledge messages under the polling API" unless @channel
        return true if @has_been_acked
        acknowledge_multiple_messages = false
        @has_been_acked = true
        @channel.ack(@delivery_tag, acknowledge_multiple_messages)
        true
      end

      def channel_open?
        return false unless @channel
        @channel.open?
      end

      def nack
        fail ::RuntimeError, "you can't acknowledge messages under the polling API" unless @channel
        return true if @has_been_nacked
        nack_multiple_messages = false
        requeue_message = true
        @has_been_nacked = true
        @channel.nack(@delivery_tag, nack_multiple_messages, requeue_message)
        true
      end

      def reject
        fail ::RuntimeError, "you can't acknowledge messages under the polling API" unless @channel
        return true if @has_been_rejected
        requeue_message = true
        @has_been_rejected = true
        @channel.reject(@delivery_tag, requeue_message)
        true
      end

      def safe_acknowledge
        acknowledge if uses_acknowledgements? && channel_open? && !has_used_delivery_tag?
      end

      def safe_nack
        nack if uses_acknowledgements? && channel_open? && !has_used_delivery_tag?
      end

      def safe_reject
        reject if uses_acknowledgements? && channel_open? && !has_used_delivery_tag?
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

    private

      def has_used_delivery_tag?
        @has_been_acked || @has_been_nacked || @has_been_rejected
      end

      def uses_acknowledgements?
        @uses_acknowledgements
      end
    end
  end
end
