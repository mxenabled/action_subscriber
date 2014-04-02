require 'rspec'

module ActionSubscriber
  module RSpec
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

    # Create a new subscriber instance. Available options are:
    #
    #  * :encoded_payload - the encoded payload object to pass into the instance.
    #  * :header - the header object to pass into the instance.
    #  * :payload - the payload object to pass to the instance.
    #  * :subscriber - the class constant corresponding to the subscriber. `described_class` is the default.
    #
    # Example
    #
    #   describe UserSubscriber do
    #     subject { mock_subscriber(:payload => proto) }
    #
    #     it 'logs the user create event' do
    #       SomeLogger.should_receive(:log)
    #       subject.created
    #     end
    #   end
    #
    def mock_subscriber(opts = {})
      encoded_payload = opts.fetch(:encoded_payload) { double('encoded payload').as_null_object }
      header = opts.fetch(:header) { double('header').as_null_object }
      subscriber_class = opts.fetch(:class) { described_class }

      env = Middleware::Env.new(subscriber_class, header, encoded_payload)
      env.payload = opts.fetch(:payload) { double('payload').as_null_object }

      return subscriber_class.new(env)
    end
  end
end

RSpec.configure do |config|
  config.include ActionSubscriber::RSpec

  shared_context 'action subscriber middleware env' do |attributes|
    let(:app) { Proc.new { |inner_env| inner_env } }
    let(:env) { ActionSubscriber::Middleware::Env.new(UserSubscriber, header, '') }
    let(:header) { amqp_header(:events, 'app.user.created', attributes || {}) }
  end

  shared_examples_for 'an action subscriber middleware' do
    include_context 'action subscriber middleware env'

    subject { described_class.new(app) }

    it "calls the stack" do
      app.better_receive(:call).with(env)
      subject.call(env)
    end
  end
end
