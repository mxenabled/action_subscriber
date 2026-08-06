module ActionSubscriber
  # Normalizes the `queue_type` setting into the value the underlying driver
  # expects for its `:type` option.
  #
  # nil is the canonical "let the broker decide" value: it leaves `x-queue-type`
  # off the wire so RabbitMQ applies its own `default_queue_type`.
  #
  # march_hare reads the driver option with
  # `@options.fetch(:type, ... Types::CLASSIC)`, and `fetch` only falls back when
  # the key is *absent*. So omitting `:type` silently declares a classic queue,
  # while passing an explicit nil is what actually suppresses the argument.
  module QueueType
    # An explicit, readable alias for nil on input. Normalizes away to nil.
    BROKER_DEFAULT = :broker_default

    SUPPORTED = [:classic, :quorum, :stream].freeze

    # Queue types that RabbitMQ only supports as durable queues.
    ALWAYS_DURABLE = [:quorum, :stream].freeze

    def self.normalize(value)
      queue_type = value.to_s.strip.downcase
      return nil if queue_type.empty? || queue_type == BROKER_DEFAULT.to_s

      queue_type = queue_type.to_sym
      unless SUPPORTED.include?(queue_type)
        raise ::ArgumentError,
          "unsupported queue_type #{value.inspect}, supported types are: #{SUPPORTED.join(', ')} " \
          "(or nil / :#{BROKER_DEFAULT} to defer to the broker)"
      end

      queue_type
    end

    # The value to hand the driver's `:type` option. Expects a normalized type.
    def self.driver_option(queue_type)
      return nil if queue_type.nil?
      queue_type.to_s
    end

    # Expects a normalized type.
    def self.always_durable?(queue_type)
      ALWAYS_DURABLE.include?(queue_type)
    end
  end
end
