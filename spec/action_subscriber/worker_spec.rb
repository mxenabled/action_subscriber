require 'spec_helper'

class WorkerTester < ActionSubscriber::Base
end

describe ::ActionSubscriber::Worker do
  describe "perform" do
    let(:env) { double(:env) }
    let(:subscriber) { WorkerTester.new("header", "payload") }

    before { env.stub(:subscriber).and_return(subscriber) }

    it "calls consume event" do
      subscriber.better_receive(:consume_event)
      subject.perform(env)
    end
  end
end
