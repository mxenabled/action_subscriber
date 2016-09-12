require "thread"
module ActionSubscriber
  class Synchronizer
    def initialize(delegate)
      @delegate = delegate
      @mutex = ::Thread::Mutex.new
    end

    def method_missing(name, *args, &block)
      @mutex.synchronize do
        @delegate.public_send(name, *args, &block)
      end
    end
  end
end
