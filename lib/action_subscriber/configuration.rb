module ActionSubscriber
  class Configuration
    attr_accessor :decoder, :default_exchange, :error_handler, :host, :port, :threadpool_size

    def initialize
      self.decoder = { 
        'application/json' => lambda { |payload| JSON.parse(payload) },
        'text/plain' => lambda { |payload| payload.dup }
      }
      self.default_exchange = :events
      self.error_handler = lambda { |error| raise }
      self.host = 'localhost'
      self.port = 5672
      self.threadpool_size = 8
    end

    ##
    # Instance Methods
    #
    def add_decoder(hash)
      self.decoder.merge!(hash)
    end

    def print
      puts ""
      puts "Rabbit Host : #{host}"
      puts "Rabbit Port : #{port}"
      puts "Threadpool Size : #{threadpool_size}"
      puts "Decoders :"
      decoder.each_key { |key| puts "  --#{key}" }

      nil
    end
  end
end
