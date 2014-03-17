require 'spec_helper'

describe ActionSubscriber::Middleware::Router do
  include_context 'middleware env'

  subject { described_class.new(app) }

  it "routes the event to the proper action" do
    env.subscriber.any_instance.better_receive(env.action)
    subject.call(env)
  end
end
