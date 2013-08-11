module ActionSubscriber
  class Threadpool
    ##
    # Class Methods
    #
    def self.busy?
      (pool.size == pool.busy_size)
    end

    def self.perform_async(*args)
      self.pool.async.perform(*args)
    end

    def self.pool
      @pool ||= ::ActionSubscriber::Worker.pool(:size => ::ActionSubscriber.config.threadpool_size)
    end

    def self.ready?
      !busy?
    end
  end
end
