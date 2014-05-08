module ActionSubscriber
  module Middleware
    class Env
      attr_accessor :payload

      attr_reader :delivery_info,
                  :encoded_payload,
                  :header,
                  :subscriber

      def initialize(subscriber, delivery_info, header, encoded_payload)
        @delivery_info = delivery_info
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
        delivery_info.try(:exchange)
      end

      def message_id
        header.try(:message_id)
      end

      def routing_key
        delivery_info.try(:routing_key)
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
