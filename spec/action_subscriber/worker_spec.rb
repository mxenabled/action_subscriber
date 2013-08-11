require 'spec_helper'

class WorkerTester < ActionSubscriber::Base
end

describe ::ActionSubscriber::Worker do
  describe "perform" do
    let(:subscriber) { WorkerTester.new("header", "payload") }

    it "calls consume event" do
      subscriber.better_receive(:consume_event)
      subject.perform(subscriber)
    end
  end
end
