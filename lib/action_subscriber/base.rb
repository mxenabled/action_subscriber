module ActionSubscriber
  class Base
    include ::ActionSubscriber::Decoder
    include ::ActionSubscriber::Router
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscriber

    ##
    # Private Attributes
    #
    private

    attr_reader :header, :raw_payload

    public

    ##
    # Constructor
    #
    def initialize(header, raw_payload)
      @header = header
      @raw_payload = raw_payload
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

  ::ActiveSupport.run_load_hooks(:action_subscriber, Base)
end
