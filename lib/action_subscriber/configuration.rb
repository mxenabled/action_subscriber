module ActionSubscriber
  class Configuration
    attr_accessor :allow_low_priority_methods,
                  :decoder,
                  :default_exchange,
                  :error_handler,
                  :heartbeat,
                  :host,
                  :hosts,
                  :mode,
                  :pop_interval,
                  :port,
                  :prefetch,
                  :threadpool_size,
                  :timeout,
                  :times_to_pop

    DEFAULTS = { 
      :allow_low_priority_methods => false,
      :default_exchange => 'events',
      :heartbeat => 5,
      :host => 'localhost',
      :hosts => [],
      :pop_interval => 100, # in milliseconds
      :port => 5672,
      :prefetch => 200,
      :threadpool_size => 8,
      :timeout => 1,
      :times_to_pop => 8
    }

    def initialize
      self.decoder = {
        'application/json' => lambda { |payload| JSON.parse(payload) },
        'text/plain' => lambda { |payload| payload.dup }
      }

      self.error_handler = lambda { |error, env_hash| raise }

      DEFAULTS.each_pair do |key, value|
        self.__send__("#{key}=", value)
      end
    end

    ##
    # Instance Methods
    #
    def add_decoder(decoders)
      decoders.each_pair do |content_type, decoder|
        unless decoder.arity == 1
          raise "ActionSubscriber decoders must have an arity of 1. The #{content_type} decoder was given with arity of #{decoder.arity}."
        end
      end

      self.decoder.merge!(decoders)
    end

    def hosts
      return @hosts if @hosts.size > 0
      [ host ]
    end

    def middleware
      @middleware ||= Middleware.initialize_stack
    end

    def inspect
      inspection_string  = <<-INSPECT.strip_heredoc
        Rabbit Host: #{host}
        Rabbit Port: #{port}
        Threadpool Size: #{threadpool_size}
        Low Priority Subscriber: #{allow_low_priority_methods}
        Decoders:
      INSPECT
      decoder.each_key { |key| inspection_string << "  --#{key}\n" }
      return inspection_string
    end
  end
end
