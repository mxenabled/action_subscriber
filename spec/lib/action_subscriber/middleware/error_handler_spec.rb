require 'action_subscriber/middleware/error_handler'

describe ActionSubscriber::Middleware::ErrorHandler do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  let(:load_error) { ::LoadError.new("Boom!") }
  let(:runtime_error) { ::RuntimeError.new("Boom!") }

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
    end

    it "calls safe_nack after execution" do
      expect(env).to receive(:safe_nack)

      subject.call(env)
    end
  end
end
