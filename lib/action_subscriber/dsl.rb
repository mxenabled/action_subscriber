module ActionSubscriber
  module DSL
    class Filter
      attr_accessor :callback_method
      attr_accessor :included_actions
      attr_accessor :excluded_actions

      def initialize(callback_method, options)
        @callback_method = callback_method
        @included_actions = @excluded_actions = []
        parse_options(options)
      end

      def matches(action)
        unless included_actions.empty?
          return included_actions.include?(action)
        end

        unless excluded_actions.empty?
          return false if excluded_actions.include?(action)
        end

        true
      end

    private

      def parse_options(options)
        return unless options

        @included_actions  = options.fetch(:if, [])
        @excluded_actions = options.fetch(:unless, [])
      end
    end

    def at_least_once!
      @_acknowledge_messages = true
      @_at_least_once = true
    end

    def at_least_once?
      !!@_at_least_once
    end

    def at_most_once!
      @_acknowledge_messages = true
      @_at_most_once = true
    end

    def at_most_once?
      !!@_at_most_once
    end

    def acknowledge_messages?
      !!@_acknowledge_messages
    end

    def around_filter(callback_method, options = nil)
      filter = Filter.new(callback_method, options)
      conditionally_add_filter!(filter)
      around_filters
    end

    def conditionally_add_filter!(filter)
      around_filters << filter unless around_filters.any? { |f| f.callback_method == filter.callback_method }
    end

    def around_filters
      @_around_filters ||= []
    end

    # Explicitly set the name of the exchange
    #
    def exchange_names(*names)
      @_exchange_names ||= []
      @_exchange_names += names.flatten.map(&:to_s)

      if @_exchange_names.empty?
        return [ ::ActionSubscriber.config.default_exchange ]
      else
        return @_exchange_names.compact.uniq
      end
    end
    alias_method :exchange, :exchange_names

    def manual_acknowledgement!
      @_acknowledge_messages = true
      @_manual_acknowedgement = true
    end

    def manual_acknowledgement?
      !!@_manual_acknowedgement
    end

    def no_acknowledgement!
      @_acknowledge_messages = false
    end

    # Explicitly set the name of a queue for the given method route
    #
    # Ex.
    #   queue_for :created, "derp.derp"
    #   queue_for :updated, "foo.bar"
    #
    def queue_for(method, queue_name)
      @_queue_names ||= {}
      @_queue_names[method] = queue_name
    end

    def queue_names
      @_queue_names ||= {}
    end

    def remote_application_name(name = nil)
      @_remote_application_name = name if name
      @_remote_application_name
    end
    alias_method :publisher, :remote_application_name

    # Explicitly set the whole routing key to use for a given method route.
    #
    def routing_key_for(method, routing_key_name)
      @_routing_key_names ||= {}
      @_routing_key_names[method] = routing_key_name
    end

    def routing_key_names
      @_routing_key_names ||= {}
    end

    def _run_action_with_filters(env, action)
      subscriber_instance = self.new(env)
      final_block = Proc.new { subscriber_instance.public_send(action) }

      first_proc = around_filters.reverse.reduce(final_block) do |block, filter|
        if filter.matches(action)
          Proc.new { subscriber_instance.send(filter.callback_method, &block) }
        else
          block
        end
      end
      first_proc.call
    end

    def _run_action_at_most_once_with_filters(env, action)
      processed_acknowledgement = false
      rejected_message = false
      processed_acknowledgement = env.acknowledge

      _run_action_with_filters(env, action)
    ensure
      rejected_message = env.reject if !processed_acknowledgement

      if !rejected_message && !processed_acknowledgement
        $stdout << <<-UNREJECTABLE
          CANNOT ACKNOWLEDGE OR REJECT THE MESSAGE

          This is a exceptional state for ActionSubscriber to enter and puts the current
          Process in the position of "I can't get new work from RabbitMQ, but also
          can't acknowledge or reject the work that I currently have" ... While rare
          this state can happen.

          Instead of continuing to try to process the message ActionSubscriber is
          sending a Kill signal to the current running process to gracefully shutdown
          so that the RabbitMQ server will purge any outstanding acknowledgements. If
          you are running a process monitoring tool (like Upstart) the Subscriber
          process will be restarted and be able to take on new work.

          ** Running a process monitoring tool like Upstart is recommended for this reason **
        UNREJECTABLE

        Process.kill(:TERM, Process.pid)
      end
    end

    def _run_action_at_least_once_with_filters(env, action)
      processed_acknowledgement = false
      rejected_message = false

      _run_action_with_filters(env, action)

      processed_acknowledgement = env.acknowledge
    rescue
      ::ActionSubscriber::MessageRetry.redeliver_message_with_backoff(env)
      processed_acknowledgement = env.acknowledge

      raise
    ensure
      rejected_message = env.reject if !processed_acknowledgement

      if !rejected_message && !processed_acknowledgement
        $stdout << <<-UNREJECTABLE
          CANNOT ACKNOWLEDGE OR REJECT THE MESSAGE

          This is a exceptional state for ActionSubscriber to enter and puts the current
          Process in the position of "I can't get new work from RabbitMQ, but also
          can't acknowledge or reject the work that I currently have" ... While rare
          this state can happen.

          Instead of continuing to try to process the message ActionSubscriber is
          sending a Kill signal to the current running process to gracefully shutdown
          so that the RabbitMQ server will purge any outstanding acknowledgements. If
          you are running a process monitoring tool (like Upstart) the Subscriber
          process will be restarted and be able to take on new work.

          ** Running a process monitoring tool like Upstart is recommended for this reason **
        UNREJECTABLE

        Process.kill(:TERM, Process.pid)
      end
    end

    def run_action_with_filters(env, action)
      case
      when at_least_once?
        _run_action_at_least_once_with_filters(env, action)
      when at_most_once?
        _run_action_at_most_once_with_filters(env, action)
      else
        _run_action_with_filters(env, action)
      end
    end
  end
end
