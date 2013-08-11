require 'spec_helper'

class TestObject < ActionSubscriber::Base
  exchange :events
  def created(foo)
  end
end

describe ActionSubscriber::Base do
  describe "inherited" do
    context "when a class has inherited from action subscriber base" do
      it "adds the class to the intherited classes collection" do
        described_class.inherited_classes.should include(TestObject)
      end
    end
  end
end
