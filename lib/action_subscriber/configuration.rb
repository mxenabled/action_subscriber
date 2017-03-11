require "yaml"
require "action_subscriber/uri"

module ActionSubscriber
  class Configuration
    attr_accessor :allow_low_priority_methods,
                  :connection_reaping_interval,
                  :connection_reaping_timeout_interval,
                  :decoder,
                  :default_exchange,
                  :error_handler,
                  :heartbeat,
                  :host,
                  :hosts,
                  :password,
                  :port,
                  :prefetch,
                  :seconds_to_wait_for_graceful_shutdown,
                  :threadpool_size,
                  :timeout,
                  :tls,
                  :tls_ca_certificates,
                  :tls_cert,
                  :tls_key,
                  :username,
                  :verify_peer,
                  :virtual_host

    CONFIGURATION_MUTEX = ::Mutex.new

    DEFAULTS = {
      :allow_low_priority_methods => false,
      :connection_reaping_interval => 6,
      :connection_reaping_timeout_interval => 5,
      :default_exchange => 'events',
      :heartbeat => 5,
      :host => 'localhost',
      :hosts => [],
      :password => "guest",
      :port => 5672,
      :prefetch => 2,
      :seconds_to_wait_for_graceful_shutdown => 30,
      :threadpool_size => 8,
      :timeout => 1,
      :tls => false,
      :tls_ca_certificates => [],
      :tls_cert => nil,
      :tls_key => nil,
      :username => "guest",
      :verify_peer => true,
      :virtual_host => "/"
    }

    ##
    # Class Methods
    #
    def self.configure_from_yaml_and_cli(cli_options = {}, reload = false)
      CONFIGURATION_MUTEX.synchronize do
        @configure_from_yaml_and_cli = nil if reload
        @configure_from_yaml_and_cli ||= begin
          env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || ENV["APP_ENV"] || "development"

          yaml_config = {}
          absolute_config_path = ::File.expand_path(::File.join("config", "action_subscriber.yml"))
          if ::File.exists?(absolute_config_path)
            yaml_config = ::YAML.load_file(absolute_config_path)[env]
          end

          ::ActionSubscriber::Configuration::DEFAULTS.each_pair do |key, value|
            setting = cli_options[key] || yaml_config[key.to_s]
            ::ActionSubscriber.config.__send__("#{key}=", setting) if setting
          end

          true
        end
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
        Rabbit Hosts: #{hosts}
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
