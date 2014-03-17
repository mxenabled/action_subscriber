module ActionSubscriber
  class Base
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscribable
    extend ::ActionSubscriber::Subscriber

    ##
    # Private Attributes
    #
    private

    attr_reader :env, :header, :payload, :raw_payload

    public

    ##
    # Constructor
    #
    def initialize(env)
      @env = env
      @header = env.header
      @payload = env.payload
      @raw_payload = env.encoded_payload
    end

    ##
    # Class Methods
    #

    def self.connection
      ::ActionSubscriber::RabbitConnection.connection
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
  end
end
