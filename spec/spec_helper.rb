require 'rubygems'
require 'bundler'

require 'simplecov'
ENV['APP_NAME'] = 'Alice'


SimpleCov.start do
  add_filter 'spec'
end

Bundler.require(:default, :development, :test)

require 'action_subscriber'
require 'active_record'

# Require spec support files
require 'support/user_subscriber'

require 'action_subscriber/rspec'
