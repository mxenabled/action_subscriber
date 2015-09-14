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

  config.before(:each, :integration => true) do
    $messages = Set.new
    ::ActionSubscriber::RabbitConnection.subscriber_connection
    ::ActionSubscriber.setup_queues!
  end
  config.after(:each, :integration => true) do
    ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
    ::ActionSubscriber::Base.inherited_classes.each do |klass|
      klass.instance_variable_set("@_queues", nil)
    end
  end
end

def verify_expectation_within(number_of_seconds, check_every = 0.02)
  waiting_since = ::Time.now
  begin
    sleep check_every
    yield
  rescue RSpec::Expectations::ExpectationNotMetError => e
    if ::Time.now - waiting_since > number_of_seconds
      raise e
    else
      retry
    end
  end
end
