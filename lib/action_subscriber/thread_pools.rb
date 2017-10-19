require "concurrent"
require "thread"

module ActionSubscriber
  module ThreadPools
    MUTEX = ::Mutex.new
    THREADPOOL_DEFAULTS = {
      :auto_terminate => true,
      :fallback_policy => :caller_runs,
      :max_queue => 10_000,
    }.freeze

    def self.threadpools
      MUTEX.synchronize do
        @threadpools ||= {}
      end
    end

    def self.setup_threadpool(name, settings)
      MUTEX.synchronize do
        @threadpools ||= {}
        fail ArgumentError, "a #{name} threadpool already exists" if @threadpools.has_key?(name)
        @threadpools[name] = create_threadpool(settings)
      end
    end

    def self.create_threadpool(settings)
      settings = THREADPOOL_DEFAULTS.merge(settings)
      num_threads = settings.delete(:threadpool_size) || ::ActionSubscriber.configuration.threadpool_size
      ::Concurrent::FixedThreadPool.new(num_threads, settings)
    end
    private_class_method :create_threadpool
  end
end
