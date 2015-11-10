module ActionSubscriber
  class Route
    attr_reader :acknowledgements,
                :action,
                :exchange,
                :routing_key,
                :subscriber,
                :queue

    def initialize(attributes)
      @acknowledgements = attributes.fetch(:acknowledgements)
      @action = attributes.fetch(:action)
      @exchange = attributes.fetch(:exchange).to_s
      @routing_key = attributes.fetch(:routing_key)
      @subscriber = attributes.fetch(:subscriber)
      @queue = attributes.fetch(:queue)
    end

    def acknowledgements?
      @acknowledgements
    end

    def queue_subscription_options
      { :manual_ack => acknowledgements? }
    end
  end
end
