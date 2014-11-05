require 'spec_helper'

class TestDSL
  extend ::ActionSubscriber::DSL
end

describe ::ActionSubscriber::DSL do
  describe "acknowledge_messages!" do
    context "when acknowledge messages is set" do
      before { TestDSL.acknowledge_messages! }

      it "acknoledges messages" do
        expect(TestDSL.acknowledge_messages?).to eq(true)
      end

      let(:expected_hash) {{ :ack => true }}

      it "returns expected queue subscription options" do
        expect(TestDSL.queue_subscription_options).to eq expected_hash
      end
    end

    context "when acknowledge_messages is not set" do
      before { TestDSL.instance_variable_set(:@_acknowledge_messages, nil) }

      it "does not acknowledge messages" do
        expect(TestDSL.acknowledge_messages?).to eq(false)
      end
    end
  end

  describe "exchange_names" do
    context "when exchange names are set" do
      before { TestDSL.exchange_names :foo, :bar }

      it "returns an array of exchange names" do
        expect(TestDSL.exchange_names).to eq(["foo", "bar"])
      end
    end

    context "when exchange names are not set" do
      before { TestDSL.instance_variable_set(:@_exchange_names, nil) }

      it "returns the default exchange" do
        expect(TestDSL.exchange_names).to eq(["events"])
      end
    end
  end

  describe "queue_for" do
    before { TestDSL.queue_for(:created, "my_app.app.user.created") }

    it "adds the method and queue name to the queue names collection" do
      expect(TestDSL.queue_names).to eq({:created => "my_app.app.user.created" })
    end
  end

  describe "remote_application_name" do
    context "when remote appliation name is set" do
      before { TestDSL.remote_application_name "app" }

      it "returns the remote application name" do
        expect(TestDSL.remote_application_name).to eq("app")
      end
    end

    context "when remote application name is not set" do
      before { TestDSL.instance_variable_set(:@_remote_application_name, nil) }

      it "returns nil" do
        expect(TestDSL.remote_application_name).to be_nil
      end
    end
  end

  describe "routing_key_for" do
    before { TestDSL.routing_key_for(:created, "app.user.created") }

    it "adds the method name to the routing key names collection" do
      expect(TestDSL.routing_key_names).to eq({:created => "app.user.created"})
    end
  end

end
