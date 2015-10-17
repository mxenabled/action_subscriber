require 'rspec'

module ActionSubscriber
  module RSpec
    class FakeChannel # A class that quacks like a RabbitMQ Channel
      def ack(delivery_tag, acknowledge_multiple)
        true
      end

      def reject(delivery_tag, requeue_message)
        true
      end
    end

    PROPERTIES_DEFAULTS = {
      :channel => FakeChannel.new,
      :content_type => "text/plain",
      :delivery_tag => "XYZ",
      :exchange => "events",
      :headers => {},
      :message_id => "MSG-123",
      :routing_key => "amigo.user.created",
    }.freeze

    # Create a new subscriber instance. Available options are:
    #
    #  * :acknowledger - the object that should receive ack/reject calls for this message (only useful for testing manual acknowledgment)
    #  * :content_type - defaults to text/plain
    #  * :encoded_payload - the encoded payload object to pass into the instance.
    #  * :exchange - defaults to "events"
    #  * :message_id - defaults to "MSG-123"
    #  * :payload - the payload object to pass to the instance.
    #  * :routing_key - defaults to amigo.user.created
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
      subscriber_class = opts.fetch(:subscriber) { described_class }
      properties = PROPERTIES_DEFAULTS.merge(opts.slice(:channel,
                                                        :content_type,
                                                        :delivery_tag,
                                                        :exchange,
                                                        :message_id,
                                                        :routing_key))


      env = ActionSubscriber::Middleware::Env.new(subscriber_class, encoded_payload, properties)
      env.payload = opts.fetch(:payload) { double('payload').as_null_object }

      return subscriber_class.new(env)
    end
  end
end

::RSpec.configure do |config|
  config.include ActionSubscriber::RSpec

  shared_context 'action subscriber middleware env' do
    let(:app) { Proc.new { |inner_env| inner_env } }
    let(:env) { ActionSubscriber::Middleware::Env.new(UserSubscriber, 'encoded payload', message_properties) }
    let(:message_properties) {{
      :channel => ::ActionSubscriber::RSpec::FakeChannel.new,
      :content_type => "text/plain",
      :delivery_tag => "XYZ",
      :exchange => "events",
      :headers => {},
      :message_id => "MSG-123",
      :routing_key => "amigo.user.created",
    }}
  end

  shared_examples_for 'an action subscriber middleware' do
    include_context 'action subscriber middleware env'

    subject { described_class.new(app) }

    it "calls the stack" do
      expect(app).to receive(:call).with(env)
      subject.call(env)
    end
  end
end
