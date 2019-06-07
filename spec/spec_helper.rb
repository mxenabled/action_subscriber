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
::ActionSubscriber.setup_default_threadpool!

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each, :integration => true) do
    $messages = Set.new
    draw_routes
    ::ActionSubscriber.setup_subscriptions!
  end
  config.after(:each, :integration => true) do
    ::ActionSubscriber.stop_subscribers!(0.1)
    ::ActionSubscriber.instance_variable_set("@route_set", nil)
    ::ActionSubscriber.instance_variable_set("@route_set_block", nil)
  end
  config.after(:suite) do
    ::ActionSubscriber.stop_subscribers!(0.1)
    ::ActionSubscriber::RabbitConnection.subscriber_disconnect!
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

# This helper method allows us to verify a subscription is cleaned up after every test.
# Its arguments are the instrumentation key and a proc that contains the work to be
# performed for each notification.
def with_instrumentation_subscription(instrumentation_key, work)
  subscription = ::ActiveSupport::Notifications.subscribe(instrumentation_key) do |name, start, finish, id, payload|
    work.call(name, start, finish, id, payload)
  end
  yield
ensure
  ::ActiveSupport::Notifications.unsubscribe(subscription)
end
