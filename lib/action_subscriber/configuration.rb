module ActionSubscriber
  class Configuration
    attr_accessor :allow_low_priority_methods,
                  :decoder,
                  :default_exchange,
                  :error_handler,
                  :heartbeat,
                  :timeout,
                  :host,
                  :hosts,
                  :port,
                  :prefetch,
                  :times_to_pop,
                  :threadpool_size

    def initialize
      self.allow_low_priority_methods = false
      self.decoder = {
        'application/json' => lambda { |payload| JSON.parse(payload) },
        'text/plain' => lambda { |payload| payload.dup }
      }
      self.default_exchange = "events"
      self.error_handler = lambda { |error, env_hash| raise }
      self.heartbeat = 5
      self.timeout = 1
      self.host = 'localhost'
      self.hosts = []
      self.port = 5672
      self.prefetch = 200
      self.times_to_pop = 8
      self.threadpool_size = 8
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
