module ActionSubscriber
  class Base
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscribable

    ##
    # Class Methods
    #

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
    # Private Instance Methods
    #
    private

    def acknowledge
      env.acknowledge
    end

    def reject
      env.reject
    end
  end
end
