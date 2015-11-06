describe ::ActionSubscriber::DSL do
  let(:subscriber) { Object.new }
  before { subscriber.extend(::ActionSubscriber::DSL) }

  describe "acknowledging messages" do
    context "when manual_acknowledgement! is set" do
      before { subscriber.manual_acknowledgement! }

      it "acknowledges messages" do
        expect(subscriber.acknowledge_messages?).to eq(true)
      end
    end

    context "when at_most_once! is set" do
      before { subscriber.at_most_once! }

      it "acknowledges messages" do
        expect(subscriber.acknowledge_messages?).to eq(true)
      end
    end

    context "when at_least_once! is set" do
      before { subscriber.at_least_once! }

      it "acknowledges messages" do
        expect(subscriber.acknowledge_messages?).to eq(true)
      end
    end

    context "when no_acknowledgement! is set" do
      before { subscriber.no_acknowledgement! }

      it "does not acknowledge messages" do
        expect(subscriber.acknowledge_messages?).to eq(false)
      end
    end

    context "default" do
      it "does not acknowledge messages" do
        expect(subscriber.acknowledge_messages?).to eq(false)
      end
    end
  end

  describe "exchange_names" do
    context "when exchange names are set" do
      before { subscriber.exchange_names :foo, :bar }

      it "returns an array of exchange names" do
        expect(subscriber.exchange_names).to eq(["foo", "bar"])
      end
    end

    context "when exchange names are not set" do
      before { subscriber.instance_variable_set(:@_exchange_names, nil) }

      it "returns the default exchange" do
        expect(subscriber.exchange_names).to eq(["events"])
      end
    end
  end

  describe "queue_for" do
    before { subscriber.queue_for(:created, "my_app.app.user.created") }

    it "adds the method and queue name to the queue names collection" do
      expect(subscriber.queue_names).to eq({:created => "my_app.app.user.created" })
    end
  end

  describe "remote_application_name" do
    context "when remote appliation name is set" do
      before { subscriber.remote_application_name "app" }

      it "returns the remote application name" do
        expect(subscriber.remote_application_name).to eq("app")
      end
    end

    context "when remote application name is not set" do
      before { subscriber.instance_variable_set(:@_remote_application_name, nil) }

      it "returns nil" do
        expect(subscriber.remote_application_name).to be_nil
      end
    end
  end

  describe "routing_key_for" do
    before { subscriber.routing_key_for(:created, "app.user.created") }

    it "adds the method name to the routing key names collection" do
      expect(subscriber.routing_key_names).to eq({:created => "app.user.created"})
    end
  end

end
