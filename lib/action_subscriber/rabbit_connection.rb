require 'thread'

module ActionSubscriber
  module RabbitConnection
    SUBSCRIBER_CONNECTION_MUTEX = ::Mutex.new
    NETWORK_RECOVERY_INTERVAL = 1.freeze

    def self.connection_threadpools
      if ::RUBY_PLATFORM == "java"
        subscriber_connections.each_with_object({}) do |(name, connection), hash|
          hash[name] = connection.instance_variable_get("@executor")
        end
      else
        [] # TODO can I get a hold of the thredpool that bunny uses?
      end
    end

    def self.setup_connection(name, settings)
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        fail ArgumentError, "a #{name} connection already exists" if subscriber_connections[name]
        subscriber_connections[name] = create_connection(settings)
      end
    end

    def self.subscriber_connected?
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        subscriber_connections.all?{|_name, connection| connection.connected?}
      end
    end

    def self.subscriber_disconnect!
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        subscriber_connections.each{|_name, connection| connection.close}
        @subscriber_connections = {}
      end
    end

    def self.with_connection(name)
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        fail ArgumentError, "there is no connection named #{name}" unless subscriber_connections[name]
        yield(subscriber_connections[name])
      end
    end

    # Private API
    def self.create_connection(settings)
      options = connection_options.merge(settings)
      if ::RUBY_PLATFORM == "java"
        options[:executor_factory] = ::Proc.new do
          ::MarchHare::ThreadPools.fixed_of_size(options[:threadpool_size])
        end
        connection = ::MarchHare.connect(options)
      else
        connection = ::Bunny.new(options)
        connection.start
        connection
      end
    end
    private_class_method :create_connection

    def self.connection_options
      {
        :automatically_recover         => true,
        :continuation_timeout          => ::ActionSubscriber.configuration.timeout * 1_000.0, #convert sec to ms
        :heartbeat                     => ::ActionSubscriber.configuration.heartbeat,
        :hosts                         => ::ActionSubscriber.configuration.hosts,
        :network_recovery_interval     => NETWORK_RECOVERY_INTERVAL,
        :pass                          => ::ActionSubscriber.configuration.password,
        :port                          => ::ActionSubscriber.configuration.port,
        :recover_from_connection_close => true,
        :threadpool_size               => ::ActionSubscriber.configuration.threadpool_size,
        :user                          => ::ActionSubscriber.configuration.username,
        :vhost                         => ::ActionSubscriber.configuration.virtual_host,
      }
    end
    private_class_method :connection_options

    def self.subscriber_connections
      @subscriber_connections ||= {}
    end
    private_class_method :subscriber_connections
  end
end
