require 'spec_helper'

class TestObject < ActionSubscriber::Base
end

describe ActionSubscriber::Base do
  describe "auto_pop!" do
    it "pops the queues of the inherited classes" do
      TestObject.better_receive(:auto_pop!)
      described_class.auto_pop!
    end
  end

  describe "auto_subscribe!" do
    it "sets up queues on the inherited classes" do
      TestObject.better_receive(:setup_queues!)
      described_class.auto_subscribe!
    end
     
    it "subscribes the inherited classes" do
      TestObject.better_receive(:auto_subscribe!)
      described_class.auto_subscribe!
    end
  end

  describe "inherited" do
    context "when a class has inherited from action subscriber base" do
      it "adds the class to the intherited classes collection" do
        described_class.inherited_classes.should include(TestObject)
      end
    end
  end
end
