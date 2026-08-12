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
      # Precedence: the route's own :durable option, then the subscriber's `durable`
      # declaration, then config.durable. Resolved here rather than in Router so that
      # both `route` and `default_routes_for` honor the subscriber's declaration.
      durable = attributes.fetch(:durable) { default_durability(attributes.fetch(:subscriber)) }
      # Falls back to the global setting when a route does not name a type, the
      # same way :prefetch does. nil means "defer to the broker".
      @queue_type = ::ActionSubscriber::QueueType.normalize(
        attributes.fetch(:queue_type) { ::ActionSubscriber.config.queue_type }
      )
      @driver_queue_type = ::ActionSubscriber::QueueType.driver_option(@queue_type)
      @durable = ::ActionSubscriber::QueueType.durable?(@queue_type, durable)
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

  private

    # nil from the subscriber means it did not express an opinion. Guarded by
    # respond_to? because a route can name any object as its subscriber -- only
    # ActionSubscriber::Base descendants carry the DSL.
    def default_durability(subscriber)
      declared = subscriber.durable if subscriber.respond_to?(:durable)
      return declared unless declared.nil?
      ::ActionSubscriber.config.durable
    end
  end
end
