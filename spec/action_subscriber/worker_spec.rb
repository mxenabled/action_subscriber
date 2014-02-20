require 'spec_helper'

class WorkerTester < ActionSubscriber::Base
end

describe ::ActionSubscriber::Worker do
  describe "perform" do
    let(:env) { ::ActionSubscriber::Env.new('header' => double(:header), 'encoded_payload' => double(:payload)) }
    let(:subscriber) { WorkerTester.new(env.header, env.encoded_payload) }

    before { env.better_stub(:subscriber).and_return(subscriber) }

    it "calls consume event" do
      subscriber.better_receive(:consume_event)
      subject.perform(env)
    end
  end
end
