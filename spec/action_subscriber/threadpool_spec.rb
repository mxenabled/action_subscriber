require 'spec_helper'

describe ::ActionSubscriber::Threadpool do
  describe "busy?" do
    context "when the workers are busy" do
      it "returns true" do
        ::ActionSubscriber::Threadpool.set_size!(2)
        ::ActionSubscriber::Threadpool.pool.better_stub(:busy_size).and_return(2)
        ::ActionSubscriber::Threadpool.busy?.should be_true
      end
    end

    context "when there are idle workers" do
      it "returns false" do
        ::ActionSubscriber::Threadpool.set_size!(2)
        ::ActionSubscriber::Threadpool.pool.better_stub(:busy_size).and_return(1)
        ::ActionSubscriber::Threadpool.busy?.should be_false
      end
    end
  end

  describe "perform_async" do
  end

  describe "pool" do
    it "returns a worker pool" do
      ::ActionSubscriber::Threadpool.pool.class.should eq Celluloid::PoolManager
    end
  end

  describe "ready?" do
    context "when the pool is busy" do
      it "returns false" do
        ::ActionSubscriber::Threadpool.better_stub(:busy?).and_return true
        ::ActionSubscriber::Threadpool.ready?.should be_false
      end
    end

    context "when the pool is not busy" do
      it "returns true" do
        ::ActionSubscriber::Threadpool.better_stub(:busy?).and_return false
        ::ActionSubscriber::Threadpool.ready?.should be_true
      end
    end
  end

  describe "set_size!" do
    it "sets the pool size" do
      ::ActionSubscriber::Threadpool.set_size!(7)
      ::ActionSubscriber::Threadpool.pool.size.should eq(7)
    end
  end
end
