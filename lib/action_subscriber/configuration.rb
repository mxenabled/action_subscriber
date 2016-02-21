module ActionSubscriber
  class Configuration
    attr_accessor :allow_low_priority_methods,
                  :async_publisher,
                  :async_publisher_drop_messages_when_queue_full,
                  :async_publisher_error_handler,
                  :async_publisher_max_queue_size,
                  :async_publisher_supervisor_interval,
                  :decoder,
                  :default_exchange,
                  :error_handler,
                  :heartbeat,
                  :host,
                  :hosts,
                  :mode,
                  :password,
                  :pop_interval,
                  :port,
                  :prefetch,
                  :publisher_confirms,
                  :seconds_to_wait_for_graceful_shutdown,
                  :username,
                  :threadpool_size,
                  :timeout,
                  :times_to_pop,
                  :virtual_host

    DEFAULT_ERROR_HANDLER = lambda do |exception|
      ::ActionSubscriber.logger.error exception.class
      ::ActionSubscriber.logger.error exception.message
      ::ActionSubscriber.logger.error exception.backtrace.join("\n") if exception.backtrace
    end

    DEFAULTS = {
      :allow_low_priority_methods => false,
      :async_publisher => 'memory',
      :async_publisher_drop_messages_when_queue_full => false,
      :async_publisher_error_handler => DEFAULT_ERROR_HANDLER,
      :async_publisher_max_queue_size => 1_000_000,
      :async_publisher_supervisor_interval => 200, # in milliseconds
      :default_exchange => 'events',
      :heartbeat => 5,
      :host => 'localhost',
      :hosts => [],
      :mode => 'subscribe',
      :pop_interval => 100, # in milliseconds
      :port => 5672,
      :prefetch => 5,
      :publisher_confirms => false,
      :seconds_to_wait_for_graceful_shutdown => 30,
      :threadpool_size => 8,
      :timeout => 1,
      :times_to_pop => 8,
      :username => "guest",
      :password => "guest",
      :virtual_host => "/"
    }

    ##
    # Class Methods
    #
    def self.configure_from_yaml_and_cli(cli_options = {})
      env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || ENV["APP_ENV"] || "development"

      yaml_config = {}
      absolute_config_path = ::File.expand_path(::File.join("config", "action_subscriber.yml"))
      if ::File.exists?(absolute_config_path)
        yaml_config = ::YAML.load_file(absolute_config_path, :safe => true)[env]
      end

      ::ActionSubscriber::Configuration::DEFAULTS.each_pair do |key, value|
        setting = cli_options[key] || yaml_config[key.to_s]
        ::ActionSubscriber.config.__send__("#{key}=", setting) if setting
      end
    end

    ##
    # Instance Methods
    #
    def initialize
      self.decoder = {
        'application/json' => lambda { |payload| JSON.parse(payload) },
        'text/plain' => lambda { |payload| payload.dup }
      }

      self.error_handler = lambda { |error, env_hash| raise }

      DEFAULTS.each_pair do |key, value|
        self.__send__("#{key}=", value)
      end
    end

    ##
    # Instance Methods
    #
    def add_decoder(decoders)
      decoders.each_pair do |content_type, decoder|
        unless decoder.arity == 1
          raise "ActionSubscriber decoders must have an arity of 1. The #{content_type} decoder was given with arity of #{decoder.arity}."
        end
      end

      self.decoder.merge!(decoders)
    end

    def async_publisher_error_handler=(handler)
      if !handler.respond_to?(:call) || handler.arity != 1
        fail "Error handler must respond to #call with an arity of 1"
      end

      @async_publisher_error_handler = handler
    end

    def connection_string=(url)
      settings = ::ActionSubscriber::URI.parse_amqp_url(url)
      settings.each do |key, value|
        send("#{key}=", value)
      end
    end

    def hosts
      return @hosts if @hosts.size > 0
      [ host ]
    end

    def middleware
      @middleware ||= Middleware.initialize_stack
    end

    def inspect
      inspection_string  = <<-INSPECT.strip_heredoc
        Rabbit Host: #{host}
        Rabbit Port: #{port}
        Threadpool Size: #{threadpool_size}
        Low Priority Subscriber: #{allow_low_priority_methods}
        Decoders:
      INSPECT
      decoder.each_key { |key| inspection_string << "  --#{key}\n" }
      return inspection_string
    end
  end
end
