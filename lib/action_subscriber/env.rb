module ActionSubscriber
  module Accessorable
    # Creates an accessor that simply sets and reads a key in the hash:
    #
    #   class Config < Hash
    #     extend Accessorable
    #
    #     hash_accessor :app
    #   end
    #
    #   config = Config.new
    #   config.app = Foo
    #   config['app'] #=> Foo
    #
    #   config['app'] = Bar
    #   config.app #=> Bar
    #
    def hash_accessor(*names) #:nodoc:
      names.each do |name|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            self['#{name}']
          end

          def #{name}=(value)
            self['#{name}'] = value
          end
        METHOD
      end
    end
  end

  class Env < Hash
    extend Accessorable

    # TODO: Add more stuff to the env: environment variables, header values, etc.
    hash_accessor :encoded_payload,
                  :header,
                  :subscriber_class

    def initialize(options = {})
      merge!(options)
    end

    def exchange
      header.try(:exchange)
    end

    def message_id
      header.try(:message_id)
    end

    def method
      header.try(:method)
    end

    # TODO: Extract decoding into a middleware
    def payload
      subscriber.try(:payload)
    end

    def routing_key
      method.try(:routing_key)
    end

    # TODO: Initialize this in the router, at the end of the stack
    def subscriber
      @subscriber ||= subscriber_class.new(header, payload)
    end
  end
end
