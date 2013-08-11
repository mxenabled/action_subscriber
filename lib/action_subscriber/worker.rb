require 'celluloid'

module ActionSubscriber
  class Worker
    include ::Celluloid

    def perform(subscriber)
      if defined?(::ActiveRecord)
        ::ActiveRecord::Base.connection_pool.with_connection do
          subscriber.consume_event
        end
      else
        subscriber.consume_event
      end
    end
  end
end
