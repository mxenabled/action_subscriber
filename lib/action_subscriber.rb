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
require "virtus"

require "action_subscriber/version"

require "action_subscriber/default_router"
require "action_subscriber/dsl"
require "action_subscriber/configuration"
require "action_subscriber/middleware"
require "action_subscriber/rabbit_connection"
require "action_subscriber/route"
require "action_subscriber/subscribable"
require "action_subscriber/subscriber/bunny"
require "action_subscriber/subscriber/march_hare"
require "action_subscriber/subscription_set"
require "action_subscriber/base"

module ActionSubscriber
  ##
  # Public Class Methods
  #

  def self.configuration
    @configuration ||= ::ActionSubscriber::Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  def self.print_subscriptions
    ::ActionSubscriber::Base.print_subscriptions
  end

  def self.start_subscribers
    routes = ::ActionSubscriber::Base.inherited_classes.map do |klass|
      ActionSubscriber::DefaultRouter.routes_for_class(klass)
    end.flatten
    subscription_set = ActionSubscriber::SubscriptionSet.new(routes)
    subscription_set.start
    subscription_set
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
