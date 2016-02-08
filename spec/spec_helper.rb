require 'rubygems'
require 'bundler'

ENV['APP_NAME'] = 'Alice'

Bundler.require(:default, :development, :test)

require 'action_subscriber'
require 'active_record'

# Require spec support files
require 'support/user_subscriber'
require 'action_subscriber/rspec'

# Silence the Logger
$TESTING = true
::ActionSubscriber::Logging.initialize_logger(nil)

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each, :integration => true) do
    $messages = Set.new
    draw_routes if respond_to?(:draw_routes)
    ::ActionSubscriber::RabbitConnection.subscriber_connection
    ::ActionSubscriber.setup_queues!
  end
  config.after(:each, :integration => true) do
    ::ActionSubscriber.stop_subscribers!
    ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
    ::ActionSubscriber.instance_variable_set("@route_set", nil)
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
