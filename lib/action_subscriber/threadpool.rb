module ActionSubscriber
  class Threadpool
    ##
    # Class Methods
    #
    def self.busy?
      !ready?
    end

    def self.new_pool(name, pool_size = nil)
      fail ArgumentError, "#{name} already exists as a threadpool" if pools.key?(name)
      pool_size ||= ::ActionSubscriber.config.threadpool_size
      pools[name] = ::Lifeguard::InfiniteThreadpool.new(
        :name => name,
        :pool_size => pool_size
      )
    end

    def self.pool(which_pool = :default)
      pools[which_pool]
    end

    def self.pools
      @pools ||= {
        :default => ::Lifeguard::InfiniteThreadpool.new(
          :name => :default,
          :pool_size => ::ActionSubscriber.config.threadpool_size
        )
      }
    end

    def self.ready?
      pools.any? { |_pool_name, pool| !pool.busy? }
    end

    def self.ready_size
      pools.inject(0) do |total_ready, (_pool_name, pool)|
        total_ready + [0, pool.pool_size - pool.busy_size].max
      end
    end

    def self.wait_to_finish_with_timeout(timeout)
      wait_loops = 0
      loop do
        wait_loops = wait_loops + 1
        any_threadpools_busy = false
        pools.each do |name, pool|
          next if pool.busy_size <= 0
          puts "  -- #{name} (remaining: #{pool.busy_size})"
          any_threadpools_busy = true
        end
        if !any_threadpools_busy
          puts "  -- Lifeguard threadpools empty"
          break
        end
        break if wait_loops >= timeout
        Thread.pass
        sleep 1
      end
    end
  end
end
