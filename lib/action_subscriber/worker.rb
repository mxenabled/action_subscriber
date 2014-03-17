require 'celluloid'

module ActionSubscriber
  class Worker
    include ::Celluloid

    def perform(env)
      ::ActionSubscriber.config.middleware.call(env)
    end
  end
end
