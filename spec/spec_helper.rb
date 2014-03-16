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

::RSpec.configure do |c|
  def amqp_channel
    channel = double(:channel)
    channel.stub(:acknowledge)
    channel.stub(:reject)
    channel
  end

  def amqp_header(exchange, routing_key, attributes = {})
    method = amqp_method(exchange, routing_key)

    AMQP::Header.new(amqp_channel, method, attributes)
  end

  def amqp_method(exchange, routing_key)
    double(:method,
      :consumer_tag => "consumer.#{routing_key}-#{Time.now.to_i}",
      :delivery_tag => 1,
      :exchange     => exchange.to_s,
      :redelivered  => false,
      :routing_key  => routing_key
    )
  end
end

shared_context 'middleware env' do |attributes|
  let(:app) { Proc.new { |inner_env| inner_env } }
  let(:env) { ActionSubscriber::Middleware::Env.new(UserSubscriber, header, '') }
  let(:header) { amqp_header(:events, 'app.user.created', attributes || {}) }
end

shared_examples_for 'a middleware' do
  include_context 'middleware env'

  subject { described_class.new(app) }

  it "calls the stack" do
    app.better_receive(:call).with(env)
    subject.call(env)
  end
end
