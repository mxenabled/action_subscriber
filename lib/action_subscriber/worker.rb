require 'celluloid'

module ActionSubscriber
  class Worker
    include ::Celluloid

    def perform(subscriber)
      ::ActionSubscriber.config.middleware.call(subscriber)
    end
  end
end
