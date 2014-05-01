module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :encoded_payload,
                  :header,
                  :subscriber

      def initialize(subscriber, header, encoded_payload)
        @header = header
        @encoded_payload = encoded_payload
        @subscriber = subscriber
      end

      # Return the last element of the routing key to indicate which action
      # to route the payload to
      #
      def action
        routing_key.split('.').last.to_s
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

      def to_hash
        {
          :action => action,
          :content_type => content_type,
          :exchange => exchange,
          :method => method,
          :routing_key => routing_key,
          :payload => payload
        }
      end
      alias_method :to_h, :to_hash

    end
  end
end
