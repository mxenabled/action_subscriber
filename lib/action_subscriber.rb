require "action_subscriber/version"

require "action_subscriber/decoder"
require "action_subscriber/dsl"
require "action_subscriber/rabbit"
require "action_subscriber/router"
require "action_subscriber/serializers"
require "action_subscriber/subscriber"
require "action_subscriber/threadpool"
require "action_subscriber/worker"
require "action_subscriber/base"

require 'active_support/core_ext'
require 'amqp'
require "celluloid"
require 'thread'

module ActionSubscriber
  ##
  # Public Class Methods
  #
  def self.env
    @_env ||= (
      ENV["RAILS_ENV"] ||
      ENV["RACK_ENV"] ||
      ENV["APP_ENV"] ||
      "development"
    )
  end

  def self.print_subscriptions
    ::ActionSubscriber::Subscriber.print_subscriptions
  end

  def self.start_queues
    reload_active_record
    load_subscribers
    ::ActionSubscriber::Rabbit::Connection.connect!
  end

  def self.start_subscribers
    reload_active_record
    load_subscribers
    ::ActionSubscriber::Rabbit::Connection.connect!
    ::ActionSubscriber::Base.auto_subscribe!
  end

  ##
  # Private Class Methods
  #
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
  private_class_method :load_subscribers

  def self.reload_active_record
    if defined?(::ActiveRecord::Base) && !::ActiveRecord::Base.connected?
      ::ActiveRecord::Base.establish_connection
    end
  end
  private_class_method :reload_active_record
end
