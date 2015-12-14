module ActionSubscriber
  class Threadpool
    ##
    # Class Methods
    #
    def self.busy?
      pools.any? do |_pool_name, pool|
        pool.pool_size == pool.busy_size
      end
    end

    def self.new_pool(name, pool_size = nil)
      fail ArgumentError, "#{name} already exists as a threadpool" if pools.key?(name)
      pool_size ||= ::ActionSubscriber.config.threadpool_size
      pools[name] = ::Lifeguard::InfiniteThreadpool.new(
        :pool_size => pool_size
      )
    end

    def self.pool(which_pool = :default)
      pools[which_pool]
    end

    def self.pools
      @pools ||= {
        :default => ::Lifeguard::InfiniteThreadpool.new(
          :pool_size => ::ActionSubscriber.config.threadpool_size
        )
      }
    end

    def self.ready?
      !busy?
    end

    def self.ready_size
      pools.inject(0) do |total_ready, (_pool_name, pool)|
        total_ready + [0, pool.pool_size - pool.busy_size].max
      end
    end
  end
end
