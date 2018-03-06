require 'action_subscriber/middleware/error_handler'

describe ActionSubscriber::Middleware::ErrorHandler do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  let(:load_error) { ::LoadError.new("Boom!") }
  let(:runtime_error) { ::RuntimeError.new("Boom!") }
  let(:message_properties) {{
    :action => :created,
    :channel => channel,
    :content_type => "text/plain",
    :delivery_tag => "XYZ",
    :exchange => "events",
    :headers => {},
    :message_id => "MSG-123",
    :routing_key => "amigo.user.created",
    :queue => "test.amigo.user.created",
    :uses_acknowledgements => true,
  }}

  it "calls safe_nack after successful execution" do
    expect(env).to receive(:safe_nack).and_call_original
    expect(env).to_not receive(:nack)

    env.acknowledge
    subject.call(env)
  end

  context "when an exception occurs" do
    context "LoadError" do
      before { allow(app).to receive(:call).and_raise(load_error) }
      it "calls the exception handler with a LoadError" do
        handler = ::ActionSubscriber.configuration.error_handler
        expect(handler).to receive(:call).with(load_error, env.to_h)

        subject.call(env)
      end
    end

    context "RuntimError" do
      before { allow(app).to receive(:call).and_raise(runtime_error) }

      it "calls the exception handler with a RuntimeError" do
        handler = ::ActionSubscriber.configuration.error_handler
        expect(handler).to receive(:call).with(runtime_error, env.to_h)

        subject.call(env)
      end

      it "calls safe_nack after execution" do
        expect(env).to receive(:safe_nack).and_call_original
        expect(env).to receive(:nack)

        subject.call(env)
      end

      context "when the channel is closed without an ack" do
        let(:channel) { ::ActionSubscriber::RSpec::FakeChannel.new(:open => false) }

        it "calls safe_nack after execution" do
          expect(env).to receive(:safe_nack).and_call_original
          expect(env).to_not receive(:nack)

          subject.call(env)
        end
      end
    end
  end
end
