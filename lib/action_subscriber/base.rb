module ActionSubscriber
  class Base
    extend ::ActionSubscriber::DefaultRouting
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscribable

    ##
    # Private Attributes
    #
    private

    attr_reader :env, :payload, :raw_payload

    public

    ##
    # Constructor
    #
    def initialize(env)
      @env = env
      @payload = env.payload
      @raw_payload = env.encoded_payload
    end

    ##
    # Class Methods
    #

    def self.connection
      ::ActionSubscriber::RabbitConnection.subscriber_connection
    end

    # Inherited callback, save a reference to our descendents
    #
    def self.inherited(klass)
      super

      inherited_classes << klass
    end

    # Storage for any classes that inherited from us
    #
    def self.inherited_classes
      @_inherited_classes ||= []
    end

    ##
    # Class Aliases
    #
    class << self
      alias_method :subscribers, :inherited_classes
    end

    ##
    # Private Instance Methods
    #
    private

    def acknowledge
      env.acknowledge
    end

    def _at_least_once_filter
      processed_acknowledgement = false
      yield
      processed_acknowledgement = acknowledge
    rescue => error
      ::ActionSubscriber::MessageRetry.redeliver_message_with_backoff(env)
      processed_acknowledgement = acknowledge
      raise error
    ensure
      rejected_message = false
      rejected_message = reject unless processed_acknowledgement

      if !processed_acknowledgement && !rejected_message
        $stdout << <<-UNREJECTABLE
          CANNOT ACKNOWLEDGE OR REJECT THE MESSAGE

          This is a exceptional state for RabbitMQ to enter and puts the current
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

    def _at_most_once_filter
      processed_acknowledgement = false
      processed_acknowledgement = acknowledge
      yield
    ensure
      rejected_message = false
      rejected_message = reject unless processed_acknowledgement

      if !processed_acknowledgement && !rejected_message
        $stdout << <<-UNREJECTABLE
          CANNOT ACKNOWLEDGE OR REJECT THE MESSAGE

          This is a exceptional state for RabbitMQ to enter and puts the current
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

    def reject
      env.reject
    end
  end
end
