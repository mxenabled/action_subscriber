require "active_support"
require "active_support/core_ext"
if ::RUBY_PLATFORM == "java"
  require 'march_hare'
else
  require "bunny"
end
require "middleware"
require "thread"

require "action_subscriber/version"

# Preload will load configuration and logging. These are the things
# that the bin stub need to initialize the configuration before load
# hooks are run when the app loads.
require "action_subscriber/preload"

require "action_subscriber/default_routing"
require "action_subscriber/dsl"
require "action_subscriber/message_retry"
require "action_subscriber/middleware"
require "action_subscriber/rabbit_connection"
require "action_subscriber/subscribable"
require "action_subscriber/thread_pools"
require "action_subscriber/bunny/subscriber"
require "action_subscriber/march_hare/subscriber"
require "action_subscriber/babou"
require "action_subscriber/route"
require "action_subscriber/route_set"
require "action_subscriber/router"
require "action_subscriber/base"

module ActionSubscriber
  ##
  # Public Class Methods
  #

  def self.configure
    yield(configuration) if block_given?
  end

  def self.draw_routes(&block)
    fail "No block provided to ActionSubscriber.draw_routes" unless block_given?

    # We need to delay the execution of this block because ActionSubscriber is
    # not configured at this point if we're calling from within the required app.
    @route_set = nil
    @draw_routes_block = block
  end

  def self.print_deprecation_warning(specific_warning)
    logger.info ("#"*50)
    logger.info ("# DEPRECATION NOTICE ")
    logger.info ("# #{specific_warning}")
    logger.info ("# The usage of multiple connections and the :concurrency setting have been deprecated in favor of using threadpools")
    logger.info ("# Please see https://github.com/mxenabled/action_subscriber#connections-deprecated for details")
    logger.info ("# If this change is a problem for your usage of action_subscriber please let us know here: https://github.com/mxenabled/action_subscriber/issues/92")
    logger.info ("#"*50)
  end

  def self.print_subscriptions
    logger.info configuration.inspect
    route_set.print_subscriptions
  end

  def self.print_threadpool_stats
    route_set.print_threadpool_stats
  end

  def self.setup_default_threadpool!
    ::ActionSubscriber::ThreadPools.setup_threadpool(:default, {})
  end

  def self.setup_subscriptions!
    route_set.setup_subscriptions!
  end

  def self.start_subscribers!
    route_set.start_subscribers!
  end

  def self.stop_subscribers!(timeout = nil)
    timeout ||= ::ActionSubscriber.configuration.seconds_to_wait_for_graceful_shutdown
    route_set.cancel_consumers!
    logger.info "waiting for threadpools to empty (maximum wait of #{timeout}sec)"
    route_set.wait_to_finish_with_timeout(timeout)
  end

  # Execution is delayed until after app loads when used with bin/action_subscriber
  require "action_subscriber/railtie" if defined?(Rails)
  ::ActiveSupport.run_load_hooks(:action_subscriber, Base)

  ##
  # Private Implementation
  #
  def self.route_set
    @route_set ||= begin
      fail "cannot start because no routes have been defined. Please make sure that you call ActionSubscriber.draw_routes when your application loads" unless @draw_routes_block
      routes = Router.draw_routes(&@draw_routes_block)
      RouteSet.new(routes)
    end
  end
  private_class_method :route_set
end
