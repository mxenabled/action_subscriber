require "active_support"
require "active_support/core_ext"
require "middleware"

require "action_subscriber/configuration"
require "action_subscriber/logging"

module ActionSubscriber
  ##
  # Public Class Methods
  #
  def self.logger
    ::ActionSubscriber::Logging.logger
  end

  def self.configuration
    @configuration ||= ::ActionSubscriber::Configuration.new
  end

  ##
  # Class aliases
  #
  class << self
    alias_method :config, :configuration
  end

  # Initialize config object
  config
end
