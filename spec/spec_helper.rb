require 'rubygems'
require 'bundler'

ENV['APP_NAME'] = 'Alice'

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
    channel = @subscription_set.connection.create_channel
    routes.each do |route|
      channel.queue_purge(route.queue)
    end
  end
  config.after(:example, :integration => true) do
    @subscription_set.stop
  end
end
