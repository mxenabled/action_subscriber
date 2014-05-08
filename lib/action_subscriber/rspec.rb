require 'rspec'

module ActionSubscriber
  module RSpec
    def amqp_channel
      channel = double(:channel)
      channel.stub(:acknowledge)
      channel.stub(:reject)
      channel.stub(:recoveries_counter).and_return(1)
      channel
    end

    # Expects a hash like
    #   :content_type => "text/plain",
    #   :headers => {
    #     "custom_header" => true
    #    }
    def amqp_properties(properties = {})
      Bunny::MessageProperties.new(properties)
    end

    # Expects a hash like
    #  :exchange => "events"
    #  :routing_key => "app.user.created"
    #  :redelivered => false
    #  :delivery_tag => "dt1"
    #  :consumer_tag => "ct1"
    def amqp_delivery_info(routing_properties = {})
      properties = routing_properties.merge(
        :exchange => "events",
        :routing_key => "app.user.created",
        :redelivered => false,
        :consumer_tag => "",
        :delivery_tag => "")
      consumer = double()
      basic_deliver = double("basic_deliver",properties)
      Bunny::DeliveryInfo.new(basic_deliver, :consumer, amqp_channel)
    end

    # Create a new subscriber instance. Available options are:
    #
    #  * :encoded_payload - the encoded payload object to pass into the instance.
    #  * :delivery_info - the delivery_info object to pass into instance
    #  * :message_properties - the message properties object to pass into the instance.
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
      delivery_info = opts.fetch(:delivery_info) { double('Bunny::DeliveryInfo') }
      properties = opts.fetch(:message_properties) { double('Bunny::MessageProperties').as_null_object }
      subscriber_class = opts.fetch(:class) { described_class }

      env = ActionSubscriber::Middleware::Env.new(subscriber_class, delivery_info, properties, encoded_payload)
      env.payload = opts.fetch(:payload) { double('payload').as_null_object }

      return subscriber_class.new(env)
    end
  end
end

RSpec.configure do |config|
  config.include ActionSubscriber::RSpec

  shared_context 'action subscriber middleware env' do
    let(:app) { Proc.new { |inner_env| inner_env } }
    let(:env) { ActionSubscriber::Middleware::Env.new(UserSubscriber, delivery_info, message_properties, '') }
    let(:delivery_info) { amqp_delivery_info }
    let(:message_properties) { amqp_properties }
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
