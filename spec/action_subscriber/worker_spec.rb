require 'spec_helper'

class WorkerTester < ActionSubscriber::Base
end

describe ::ActionSubscriber::Worker do
  describe "perform" do
    include_context 'middleware env'

    let(:subscriber) { WorkerTester.new(env) }

    before { env.stub(:subscriber).and_return(subscriber) }

    it "calls consume event" do
      subscriber.better_receive(:consume_event)
      subject.perform(env)
    end
  end
end
