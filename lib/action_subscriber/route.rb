module ActionSubscriber
  class Route
    attr_reader :acknowledgements,
                :action,
                :concurrency,
                :durable,
                :exchange,
                :prefetch,
                :queue,
                :routing_key,
                :subscriber,
                :threadpool_name

    def initialize(attributes)
      @acknowledgements = attributes.fetch(:acknowledgements)
      @action = attributes.fetch(:action)
      @concurrency = attributes.fetch(:concurrency, 1)
      @durable = attributes.fetch(:durable)
      @exchange = attributes.fetch(:exchange).to_s
      @prefetch = attributes.fetch(:prefetch) { ::ActionSubscriber.config.prefetch }
      @queue = attributes.fetch(:queue)
      @routing_key = attributes.fetch(:routing_key)
      @subscriber = attributes.fetch(:subscriber)
      @threadpool_name = attributes.fetch(:threadpool_name)
    end

    def acknowledgements?
      @acknowledgements
    end

    def queue_subscription_options
      { :manual_ack => acknowledgements? }
    end
  end
end
