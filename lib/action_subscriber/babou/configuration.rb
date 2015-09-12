module Babou
  class Configuration
    DEFAULTS = {
      :mode => "prowl",
      :host => "localhost",
      :hosts => [],
      :pop_interval => 100, # in milliseconds
      :port => 5672,
      :threadpool_size => 8,
      :times_to_pop => 8
    }

    attr_accessor :mode, :pop_interval, :host, :hosts, :port, :threadpool_size, :times_to_pop

    def initialize
      DEFAULTS.each_pair do |key, value|
        self.__send__("#{key}=", value)
      end
    end
  end
end
