require 'action_subscriber/middleware/error_handler'

describe ActionSubscriber::Middleware::ErrorHandler do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  let(:error) { ::RuntimeError.new("Boom!") }

  context "when an exception occurs" do
    before { allow(app).to receive(:call).and_raise(error) }

    it "calls the exception handler" do
      handler = ::ActionSubscriber.configuration.error_handler
      expect(handler).to receive(:call).with(error, env.to_h)

      subject.call(env)
    end

    context "when the subscriber was expecting to acknowledge the message" do
      before { allow(env.subscriber).to receive(:acknowledge_messages_after_processing?).and_return(true) }

      it "calls the exception handler and rejects the message" do
        handler = ::ActionSubscriber.configuration.error_handler
        expect(handler).to receive(:call).with(error, env.to_h)
        expect(env).to receive(:reject).with(no_args)

        subject.call(env)
      end
    end
  end
end
