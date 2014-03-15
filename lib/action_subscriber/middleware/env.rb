module ActionSubscriber
  module Middleware
    class Env
      attr_reader :encoded_payload,
                  :header,
                  :subscriber_class

      def initialize(subscriber_class, header, encoded_payload)
        @header = header
        @encoded_payload = encoded_payload
        @subscriber_class = subscriber_class
      end

      def exchange
        header.try(:exchange)
      end

      def message_id
        header.try(:message_id)
      end

      def method
        header.try(:method)
      end

      # TODO: Extract decoding into a middleware
      def payload
        subscriber.payload
      end

      def routing_key
        method.try(:routing_key)
      end

      # TODO: Initialize this in the router, at the end of the stack
      def subscriber
        @subscriber ||= subscriber_class.new(header, encoded_payload)
      end
    end
  end
end
