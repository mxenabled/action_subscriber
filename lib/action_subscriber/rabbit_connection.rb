require 'thread'

module ActionSubscriber
  module RabbitConnection
    SUBSCRIBER_CONNECTION_MUTEX = ::Mutex.new

    def self.subscriber_connected?
      with_connection{|connection| connection.connected? }
    end

    def self.subscriber_disconnect!
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        @subscriber_connection.close if @subscriber_connection
        @subscriber_connection = nil
      end
    end

    def self.with_connection
      SUBSCRIBER_CONNECTION_MUTEX.synchronize do
        @subscriber_connection ||= create_connection
        yield(@subscriber_connection)
      end
    end

    # Private API
    def self.create_connection
      options = connection_options
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
        :network_recovery_interval     => ::ActionSubscriber.configuration.network_recovery_interval,
        :pass                          => ::ActionSubscriber.configuration.password,
        :port                          => ::ActionSubscriber.configuration.port,
        :recover_from_connection_close => true,
        :threadpool_size               => ::ActionSubscriber.configuration.threadpool_size,
        :tls                           => ::ActionSubscriber.configuration.tls,
        :tls_ca_certificates           => ::ActionSubscriber.configuration.tls_ca_certificates,
        :tls_cert                      => ::ActionSubscriber.configuration.tls_cert,
        :tls_key                       => ::ActionSubscriber.configuration.tls_key,
        :user                          => ::ActionSubscriber.configuration.username,
        :verify_peer                   => ::ActionSubscriber.configuration.verify_peer,
        :vhost                         => ::ActionSubscriber.configuration.virtual_host,
      }
    end
    private_class_method :connection_options
  end
end
