require 'spec_helper'
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
  end
end
