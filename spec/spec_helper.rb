require 'rubygems'
require 'bundler'

unless ENV["NO_COV"]
  require "simplecov"
  ::SimpleCov.start do
    enable_coverage :branch
    add_filter "spec"
  end
end

ENV['APP_NAME'] = 'Alice'

Bundler.require(:default, :development, :test)

require 'action_subscriber'
require 'active_record'

# Require spec support files
require 'support/user_subscriber'
require 'support/rabbitmq'
require 'action_subscriber/rspec'

# Silence the Logger
$TESTING = true
::ActionSubscriber::Logging.initialize_logger(nil)
::ActionSubscriber.setup_default_threadpool!

# Point the publisher and the subscriber at the same broker the helper talks to, so a
# local run can target something other than localhost:5672 -- e.g. two containers on
# 5673/5674 when checking a change against both RabbitMQ series at once.
#
# Both gems pass :hosts through to the driver, and march_hare builds its address list
# from :hosts alone -- a bare hostname there means port 5672 no matter what :port says.
# So the port has to travel in the host entry itself.
SPEC_RABBITMQ_ADDRESS = "#{RabbitMQTestHelper.host}:#{RabbitMQTestHelper.port}".freeze

[::ActionSubscriber, ::ActivePublisher].each do |gem_module|
  gem_module.configure do |config|
    config.host = RabbitMQTestHelper.host
    config.port = RabbitMQTestHelper.port
    config.hosts = [SPEC_RABBITMQ_ADDRESS]
  end
end

# Lets CI run the whole integration suite against settings other than the defaults. The
# 4.x jobs need one of these, because RabbitMQ 4.x denies the transient queues a default
# route declares -- `quorum` forces durability via the queue type, `durable` sets it
# directly. See spec/support/rabbitmq.rb.
#
# Applied per integration example rather than globally, so they cannot reach the unit
# specs that assert what the *defaults* are.
SPEC_CONFIG_OVERRIDES = {
  :queue_type => RabbitMQTestHelper.env("ACTION_SUBSCRIBER_QUEUE_TYPE"),
  :durable => RabbitMQTestHelper.env("ACTION_SUBSCRIBER_DURABLE") { |value| value == "true" },
}.reject { |_setting, value| value.nil? }.freeze

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Fail fast with a clear message (rather than a flurry of Bunny reconnect warnings)
  # if the broker isn't up yet when the integration suite starts.
  config.before(:suite) do
    next unless RSpec.world.filtered_examples.values.flatten.any? { |ex| ex.metadata[:integration] }

    RabbitMQTestHelper.wait_for_rabbitmq!
    # Start from a clean slate: a queue left behind by a previous run under a different
    # ACTION_SUBSCRIBER_QUEUE_TYPE would fail every redeclaration with
    # PRECONDITION_FAILED, because type and durability are fixed at declaration.
    RabbitMQTestHelper.delete_all_queues!
  end

  # An around hook so it wraps the before hook below -- routes read the config when they
  # are drawn. Examples that need particular settings use :as_config, which nests inside
  # this one and therefore wins.
  config.around(:each, :integration => true) do |example|
    with_action_subscriber_config(SPEC_CONFIG_OVERRIDES) { example.run }
  end

  # Opt in from any example or group with, e.g.:
  #   describe "...", :as_config => { :queue_type => nil, :durable => true } do
  config.around(:each) do |example|
    with_action_subscriber_config(example.metadata[:as_config] || {}) { example.run }
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

# Set ActionSubscriber configuration for the duration of the block and put it back
# afterwards, even if the block raises -- a leaked setting reappears as a
# PRECONDITION_FAILED from some unrelated spec, since queue type and durability are
# fixed when a queue is declared.
def with_action_subscriber_config(settings)
  return yield if settings.empty?

  original = settings.keys.map { |setting| [setting, ::ActionSubscriber.config.public_send(setting)] }
  settings.each { |setting, value| ::ActionSubscriber.config.public_send("#{setting}=", value) }
  yield
ensure
  original.each { |setting, value| ::ActionSubscriber.config.public_send("#{setting}=", value) } if original
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
