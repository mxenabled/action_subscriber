require 'spec_helper'
require 'action_subscriber/middleware/error_handler'

describe ActionSubscriber::Middleware::ErrorHandler do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  context "when an exception occurs" do
    before { app.stub(:call).and_raise('Boom!') }

    it "calls the exception handler" do
      ::ActionSubscriber.configuration.error_handler.should_receive(:call)
      subject.call(env)
    end
  end
end
