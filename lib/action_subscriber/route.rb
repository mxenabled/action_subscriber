module ActionSubscriber
  class Route
    include Virtus.value_object

    values do
      attribute :action, Symbol
      attribute :acknowledge_messages, Boolean, :default => false
      attribute :exchange, String
      attribute :prefetch, Fixnum, :default => 50
      attribute :queue, String
      attribute :routing_key, String
      attribute :subscriber, Class
    end
  end
end
