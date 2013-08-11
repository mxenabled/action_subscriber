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

    # Loop over all subscribers and pull messages if there are
    # any waiting in the queue for us.
    #
    def self.auto_pop!
      inherited_classes.each do |klass|
        klass.auto_pop!
      end
    end

    # Loop over all subscribers and register each as
    # a subscriber.
    #
    def self.auto_subscribe!
      inherited_classes.each do |klass|
        klass.setup_queues!
        klass.auto_subscribe!
      end
    end

    def self.connection
      ::ActionSubscriber::Rabbit::Connection.connection
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

    def self.print_global_settings
      puts "TODO : Global settings should be displayed here"
    end

    def self.print_subscriptions
      print_global_settings

      inherited_classes.each do |klass|
        puts " * #{klass.name} * "
        klass.print_routes
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
