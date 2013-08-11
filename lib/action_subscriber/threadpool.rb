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

    def self.pool(reload = false, size = 8)
      if reload || @pool.nil?
        @pool = ::ActionSubscriber::Worker.pool(:size => size)
      end
      @pool
    end

    def self.ready?
      !busy?
    end

    def self.set_size!(size)
      self.pool(true, size)
    end
  end
end
