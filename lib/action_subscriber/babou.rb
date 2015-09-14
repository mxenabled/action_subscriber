module ActionSubscriber
  module Babou
    ##
    # Class Methods
    #
    def self.configure_from_yaml_and_cli(cli_options = {})
      env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || ENV["APP_ENV"] || "development"

      yaml_config = {}
      babou_absolute_config_path = ::File.expand_path(::File.join("config", "babou.yml"))
      if ::File.exists?(babou_absolute_config_path)
        yaml_config = ::YAML.load_file(babou_absolute_config_path, :safe => true)[env]
      end

      ::ActionSubscriber::Configuration::DEFAULTS.each_pair do |key, value|
        setting = cli_options[key] || yaml_config[key.to_s]
        ::ActionSubscriber.config.__send__("#{key}=", setting) if setting
      end
    end

    def self.auto_pop!
      @pounce_mode = true
      reload_active_record
      load_subscribers unless subscribers_loaded?
      sleep_time = ::ActionSubscriber.configuration.pop_interval.to_i / 1000.0

      ::ActionSubscriber.start_queues
      puts "\nAction Subscriber is popping messages every #{sleep_time} seconds.\n"

      # How often do we want the timer checking for new pops
      # since we included an eager popper we decreased the
      # default check interval to 100ms
      while true
        ::ActionSubscriber.auto_pop! unless shutting_down?
        sleep sleep_time 
        break if shutting_down?
      end
    end

    def self.pounce?
      !!@pounce_mode
    end

    def self.start_subscribers
      @prowl_mode = true
      reload_active_record
      load_subscribers unless subscribers_loaded?

      ::ActionSubscriber.start_subscribers
      puts "\nAction Subscriber connected\n"

      while true
        sleep 1.0 #just hang around waiting for messages
        break if shutting_down?
      end
    end

    def self.prowl?
      !!@prowl_mode
    end

    def self.load_subscribers
      subscription_paths = ["subscriptions", "subscribers"]
      path_prefixes = ["lib", "app"]
      cloned_paths = subscription_paths.dup

      path_prefixes.each do |prefix|
        cloned_paths.each { |path| subscription_paths << "#{prefix}/#{path}" }
      end

      absolute_subscription_paths = subscription_paths.map{ |path| ::File.expand_path(path) }
      absolute_subscription_paths.each do |path|
        if ::File.exists?("#{path}.rb")
          load("#{path}.rb")
        end

        if ::File.directory?(path)
          ::Dir[::File.join(path, "**", "*.rb")].sort.each do |file|
            load file
          end
        end
      end
    end

    def self.reload_active_record
      if defined?(::ActiveRecord::Base) && !::ActiveRecord::Base.connected?
        ::ActiveRecord::Base.establish_connection
      end
    end

    def self.stop_server!
      @shutting_down = true
    end

    def self.shutting_down?
      !!@shutting_down
    end

    def self.subscribers_loaded?
      !::ActionSubscriber::Base.inherited_classes.empty?
    end
  end
end
