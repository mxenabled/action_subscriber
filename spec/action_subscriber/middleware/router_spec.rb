require 'spec_helper'

describe ActionSubscriber::Middleware::Router do
  include_context 'middleware env'

  subject { described_class.new(app) }

  it "consumes the event" do
    env.subscriber.better_receive(:consume_event)
    subject.call(env)
  end
end
