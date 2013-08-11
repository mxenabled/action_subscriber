require 'spec_helper'

class TestObject
  include ::ActionSubscriber::DSL
end

describe ::ActionSubscriber::DSL do
  describe "acknowledge_messages!" do
    context "when acknowledge messages is set" do
      before { TestObject.acknowledge_messages! }

      it "acknoledges messages" do
        TestObject.acknowledge_messages?.should be_true
      end

      let(:expected_hash) {{ :ack => true }}

      it "returns expected queue subscription options" do
        TestObject.queue_subscription_options.should eq expected_hash
      end
    end

    context "when acknowledge_messages is not set" do
      before { TestObject.instance_variable_set(:@_acknowledge_messages, nil) }

      it "does not acknowledge messages" do
        TestObject.acknowledge_messages?.should be_false
      end
    end
  end

  describe "exchange_names" do
    context "when exchange names are set" do
      before { TestObject.exchange_names :foo, :bar }

      it "returns an array of exchange names" do
        TestObject.exchange_names.should eq([:foo, :bar])
      end
    end

    context "when exchange names are not set" do
      before { TestObject.instance_variable_set(:@_exchange_names, nil) }

      it "returns an empty array" do
        TestObject.exchange_names.should eq([])
      end
    end
  end

  describe "queue_for" do
    before { TestObject.queue_for(:created, "my_app.app.user.created") }

    it "adds the method and queue name to the queue names collection" do
      TestObject.queue_names.should eq({:created => "my_app.app.user.created" })
    end
  end

  describe "remote_application_name" do
    context "when remote appliation name is set" do
      before { TestObject.remote_application_name "app" }

      it "returns the remote application name" do
        TestObject.remote_application_name.should eq("app")
      end
    end

    context "when remote application name is not set" do
      before { TestObject.instance_variable_set(:@_remote_application_name, nil) }

      it "returns nil" do
        TestObject.remote_application_name.should be_nil
      end
    end
  end

  describe "routing_key_for" do
    before { TestObject.routing_key_for(:created, "app.user.created") }
    
    it "adds the method name to the routing key names collection" do
      TestObject.routing_key_names.should eq({:created => "app.user.created"})
    end
  end

end
