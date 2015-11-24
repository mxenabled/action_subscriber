module ActionSubscriber
  class Threadpool
    ##
    # Class Methods
    #
    def self.busy?
      (pool.pool_size == pool.busy_size)
    end

    def self.number_of_jobs_queued
      pool.instance_variable_get('@queued_jobs').size
    end

    def self.perform_async(*args)
      self.pool.async.perform(*args)
    end

    def self.pool
      @pool ||= ::Lifeguard::InfiniteThreadpool.new(
        :pool_size => ::ActionSubscriber.config.threadpool_size
      )
    end

    def self.print_threadpool_stackraces
      $stderr.puts "ActionSubscriber :: Threadpool stacktraces\n"
      pool.instance_variable_get('@busy_threads').each do |thread|
        $stderr.puts <<-THREAD_TRACE
          #{thread.inspect}:
          #{thread.backtrace.try(:join, $INPUT_RECORD_SEPARATOR)}"
        THREAD_TRACE
      end
    end

    def self.ready?
      !busy?
    end

    def self.ready_size
      ready_size = pool.pool_size - pool.busy_size
      return ready_size >= 0 ? ready_size : 0
    end
  end
end
