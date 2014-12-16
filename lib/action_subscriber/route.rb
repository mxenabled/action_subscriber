module ActionSubscriber
  class Route
    include Virtus.value_object

    values do
      attribute :action, Symbol
      attribute :acknowledge_messages, Boolean
      attribute :exchange, String
      attribute :prefetch, Fixnum
      attribute :queue, String
      attribute :routing_key, String
      attribute :subscriber, Class
    end
  end
end
