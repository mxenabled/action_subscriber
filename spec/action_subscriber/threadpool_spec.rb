require 'spec_helper'

describe ::ActionSubscriber::Threadpool do
  describe "busy?" do
    context "when the workers are busy" do
      it "returns true" do
        allow(::ActionSubscriber::Threadpool.pool).to receive(:busy_size).and_return(8)
        expect(::ActionSubscriber::Threadpool.busy?).to eq(true)
      end
    end

    context "when there are idle workers" do
      it "returns false" do
        allow(::ActionSubscriber::Threadpool.pool).to receive(:busy_size).and_return(1)
        expect(::ActionSubscriber::Threadpool.busy?).to eq(false)
      end
    end
  end

  describe "ready?" do
    context "when the pool is busy" do
      it "returns false" do
        allow(::ActionSubscriber::Threadpool).to receive(:busy?).and_return true
        expect(::ActionSubscriber::Threadpool.ready?).to eq(false)
      end
    end

    context "when the pool is not busy" do
      it "returns true" do
        allow(::ActionSubscriber::Threadpool).to receive(:busy?).and_return false
        expect(::ActionSubscriber::Threadpool.ready?).to eq(true)
      end
    end
  end
end
