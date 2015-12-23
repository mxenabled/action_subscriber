# Taken from https://github.com/mperham/sidekiq/blob/7f882787e53d234042ff18099241403300a47585/lib/sidekiq/logging.rb
require 'time'
require 'logger'

module ActionSubscriber
  module Logging
    def self.initialize_logger(log_target = STDOUT)
      oldlogger = defined?(@logger) ? @logger : nil
      @logger = Logger.new(log_target)
      @logger.level = Logger::INFO
      oldlogger.close if oldlogger && !$TESTING # don't want to close testing's STDOUT logging
      @logger
    end

    def self.logger
      defined?(@logger) ? @logger : initialize_logger
    end

    def self.logger=(log)
      @logger = (log ? log : Logger.new('/dev/null'))
    end

    def logger
      ::ActionSubscriber::Logging.logger
    end
  end
end
