module ActionSubscriber
  class Base
    extend ::ActionSubscriber::DefaultRouting
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscribable
    if ::RUBY_PLATFORM == "java"
      extend ::ActionSubscriber::MarchHare::Subscriber
    else
      extend ::ActionSubscriber::Bunny::Subscriber
    end

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

    def self.print_subscriptions
      puts ::ActionSubscriber.configuration.inspect
      puts ""

      inherited_classes.each do |klass|
        puts klass.inspect
      end

      nil
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
      yield
      acknowledge
    rescue => error
      ::ActionSubscriber::MessageRetry.redeliver_message_with_backoff(env)
      acknowledge
      raise error
    end

    def _at_most_once_filter
      acknowledge
      yield
    end

    def reject
      env.reject
    end
  end
end
