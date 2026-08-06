module ActionSubscriber
  class Route
    attr_reader :acknowledgements,
                :action,
                :driver_queue_type,
                :durable,
                :exchange,
                :prefetch,
                :queue,
                :queue_type,
                :routing_key,
                :subscriber,
                :threadpool_name

    def initialize(attributes)
      @acknowledgements = attributes.fetch(:acknowledgements)
      @action = attributes.fetch(:action)
      durable = attributes.fetch(:durable)
      # Falls back to the global setting when a route does not name a type, the
      # same way :prefetch does. nil means "defer to the broker".
      @queue_type = ::ActionSubscriber::QueueType.normalize(
        attributes.fetch(:queue_type) { ::ActionSubscriber.config.queue_type }
      )
      @driver_queue_type = ::ActionSubscriber::QueueType.driver_option(@queue_type)
      # Quorum and stream queues only exist as durable queues, so the broker
      # rejects them otherwise. march_hare already forces this internally.
      @durable = ::ActionSubscriber::QueueType.always_durable?(@queue_type) || durable
      @exchange = attributes.fetch(:exchange).to_s
      @prefetch = attributes.fetch(:prefetch) { ::ActionSubscriber.config.prefetch }
      @queue = attributes.fetch(:queue)
      @routing_key = attributes.fetch(:routing_key)
      @subscriber = attributes.fetch(:subscriber)
      @threadpool_name = attributes.fetch(:threadpool_name)
      if attributes.has_key?(:concurrency)
        concurrency = attributes[:concurrency]
        ::ActionSubscriber.print_deprecation_warning("setting prefetch for #{@queue} to #{concurrency}")
        @prefetch = concurrency
      end
    end

    def acknowledgements?
      @acknowledgements
    end

    def queue_subscription_options
      { :manual_ack => acknowledgements? }
    end
  end
end
