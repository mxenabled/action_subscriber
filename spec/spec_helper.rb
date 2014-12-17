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

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each, :integration => true) do |example|
    $messages = Set.new
    @subscription_set = ActionSubscriber::SubscriptionSet.new(routes)
  end
  config.after(:example, :integration => true) do
    @subscription_set.stop
  end
end
