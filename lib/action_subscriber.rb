require "active_support"
require "active_support/core_ext"
if ::RUBY_PLATFORM == "java"
  require 'march_hare'
else
  require "bunny"
end
require "lifeguard"
require "middleware"
require "thread"

require "action_subscriber/version"

require "action_subscriber/default_routing"
require "action_subscriber/dsl"
require "action_subscriber/configuration"
require "action_subscriber/message_retry"
require "action_subscriber/middleware"
require "action_subscriber/rabbit_connection"
require "action_subscriber/subscribable"
require "action_subscriber/bunny/subscriber"
require "action_subscriber/march_hare/subscriber"
require "action_subscriber/babou"
require "action_subscriber/publisher"
require "action_subscriber/threadpool"
require "action_subscriber/base"

module ActionSubscriber
  ##
  # Public Class Methods
  #

  # Loop over all subscribers and pull messages if there are
  # any waiting in the queue for us.
  #
  def self.auto_pop!
    return if ::ActionSubscriber::Threadpool.busy?
    ::ActionSubscriber::Base.inherited_classes.each do |klass|
      klass.auto_pop!
    end
  end

  # Loop over all subscribers and register each as
  # a subscriber.
  #
  def self.auto_subscribe!
    ::ActionSubscriber::Base.inherited_classes.each do |klass|
      klass.auto_subscribe!
    end
  end

  def self.configuration
    @configuration ||= ::ActionSubscriber::Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  def self.print_subscriptions
    ::ActionSubscriber::Base.print_subscriptions
  end

  def self.setup_queues!
    ::ActionSubscriber::Base.inherited_classes.each do |klass|
      klass.setup_queues!
    end
  end

  def self.start_queues
    ::ActionSubscriber::RabbitConnection.subscriber_connection
    setup_queues!
    print_subscriptions
  end

  def self.start_subscribers
    ::ActionSubscriber::RabbitConnection.subscriber_connection
    setup_queues!
    auto_subscribe!
    print_subscriptions
  end

  ##
  # Class aliases
  #
  class << self
    alias_method :config, :configuration
  end

  # Initialize config object
  config

  ::ActiveSupport.run_load_hooks(:action_subscriber, Base)
end

require "action_subscriber/railtie" if defined?(Rails)

at_exit do
  ::ActionSubscriber::RabbitConnection.publisher_disconnect!
end
