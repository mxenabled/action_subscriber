module ActionSubscriber
  class Babou
    ##
    # Class Methods
    #
    def self.pounce
      puts "Babou started in pounce mode."
      ::ActionSubscriber.start_queues
      ::ActionSubscriber.print_subscriptions

      while true
        ::ActionSubscriber.auto_pop!
      end
    end

    def self.prowl
      puts "Babou is prowling for rabbits."
      ::EventMachine.run do
        ::EventMachine.error_handler do |e|
          # TODO: support custom error handling
        end

        ::ActionSubscriber.start_subscribers
        ::ActionSubscriber.print_subscriptions
      end
    end
  end
end
