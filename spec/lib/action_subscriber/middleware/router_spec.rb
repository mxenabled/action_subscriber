require 'spec_helper'

describe ActionSubscriber::Middleware::Router do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it "routes the event to the proper action" do
    allow_any_instance_of(env.subscriber).to receive(env.action)
    subject.call(env)
  end

  it "acknowledges messages after processing if the subscriber flag is set" do
    allow(env.subscriber).to receive(:acknowledge_messages_after_processing?).and_return(true)
    expect(env).to receive(:acknowledge)
    subject.call(env)
  end

  it "acknowledges messages before processing if the subscriber flag is set" do
    allow(env.subscriber).to receive(:acknowledge_messages_before_processing?).and_return(true)
    expect(env).to receive(:acknowledge)
    subject.call(env)
  end
end
