require 'spec_helper'

class WorkerTester < ActionSubscriber::Base
end

describe ::ActionSubscriber::Worker do
  describe "perform" do
    include_context 'middleware env'

    let(:subscriber) { WorkerTester.new(env) }

    it "calls the middleware stack" do
      ActionSubscriber.config.middleware.better_receive(:call).with(env)
      subject.perform(env)
    end
  end
end
