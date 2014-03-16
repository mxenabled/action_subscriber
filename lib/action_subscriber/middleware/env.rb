module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :encoded_payload,
                  :header,
                  :subscriber_class

      def initialize(subscriber_class, header, encoded_payload)
        @header = header
        @encoded_payload = encoded_payload
        @subscriber_class = subscriber_class
      end

      def content_type
        header.try(:content_type).to_s
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
