module ActionSubscriber
  class Configuration
    attr_accessor :allow_low_priority_methods,
                  :decoder,
                  :default_exchange,
                  :error_handler,
                  :heartbeat,
                  :timeout,
                  :host,
                  :port,
                  :times_to_pop,
                  :threadpool_size,
                  :middleware

    def initialize
      self.allow_low_priority_methods = false
      self.decoder = {
        'application/json' => lambda { |payload| JSON.parse(payload) },
        'text/plain' => lambda { |payload| payload.dup }
      }
      self.default_exchange = :events
      self.error_handler = lambda { |error| raise }
      self.heartbeat = 1.0
      self.timeout = 0.5
      self.host = 'localhost'
      self.port = 5672
      self.times_to_pop = 8
      self.threadpool_size = 8
    end

    ##
    # Instance Methods
    #
    def add_decoder(decoders)
      decoders.each_pair do |content_type, decoder|
        unless [1, 3].include?(decoder.arity)
          raise "ActionSubscriber decoders must have an arity of 1 or 3. The #{content_type} decoder was given with arity of #{decoder.arity}."
        end
      end

      self.decoder.merge!(decoders)
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
