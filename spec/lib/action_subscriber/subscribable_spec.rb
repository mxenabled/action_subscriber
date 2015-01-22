TestSubscriber = Class.new(ActionSubscriber::Base) do
  def updated
  end

  def updated_low
  end
end
TestSubscriber.remote_application_name :bob

describe ActionSubscriber::Subscribable do
  describe "allow_low_priority_methods?" do
    after do
      ::ActionSubscriber.configure { |config| config.allow_low_priority_methods = false }
    end

    it "when the configuration is false is is false" do
      ::ActionSubscriber.configure { |config| config.allow_low_priority_methods = false }
      expect(TestSubscriber.allow_low_priority_methods?).to eq(false)
    end

    it "when the configuration is true it is true" do
      ::ActionSubscriber.configure { |config| config.allow_low_priority_methods = true }
      expect(TestSubscriber.allow_low_priority_methods?).to eq(true)
    end
  end

  describe "filter_low_priority_methods" do
    context "when allow_low_priority_methods? is false" do
      before { allow(TestSubscriber).to receive(:allow_low_priority_methods?).and_return(false) }

      it "removes low priority methods" do
        filtered_methods = TestSubscriber.filter_low_priority_methods([:updated, :updated_low])
        expect(filtered_methods).to eq([:updated])
      end
    end

    context "when allow_low_priority_methods? is true" do
      before { allow(TestSubscriber).to receive(:allow_low_priority_methods?).and_return(true) }

      it "allows low priority methods" do
        filtered_methods = TestSubscriber.filter_low_priority_methods([:updated, :updated_low])
        expect(filtered_methods).to eq([:updated, :updated_low])
      end
    end
  end

  describe "generate_queue_name" do
    it "returns a queue name" do
      queue_name = TestSubscriber.generate_queue_name(:created)
      expect(queue_name).to eq("alice.bob.test.created")
    end
  end

  describe "generate_routing_key_name" do
    it "returns a routing key name" do
      routing_key_name = TestSubscriber.generate_routing_key_name(:created)
      expect(routing_key_name).to eq("bob.test.created")
    end
  end

  describe "local_application_name" do
    it "returns the local application name" do
      expect(TestSubscriber.local_application_name).to eq("alice")
    end
  end

  describe "queue_name_for_method" do
    before { TestSubscriber.instance_variable_set(:@_queue_names, nil) }

    context "when the queue is already registered" do
      it "returns the registered queue" do
        TestSubscriber.queue_for(:created, "foo.bar")
        queue_name = TestSubscriber.queue_name_for_method(:created)
        expect(queue_name).to eq("foo.bar")
      end
    end

    context "when the queue is not registered" do
      it "generates a queue name" do
        queue_name = TestSubscriber.queue_name_for_method(:created)
        expect(queue_name).to eq("alice.bob.test.created")
      end

      it "registers the generated queue" do
        queue_name = TestSubscriber.queue_name_for_method(:created)
        expect(TestSubscriber.queue_names).to eq({:created =>"alice.bob.test.created"})
      end
    end
  end

  describe "resource_name" do
    it "returns the resource name" do
      expect(TestSubscriber.resource_name).to eq("test")
    end
  end

  describe "routing_key_name_for_method" do
    before { TestSubscriber.instance_variable_set(:@_routing_key_names, nil) }

    context "when the routing key is already registered" do
      it "returns the registered routing key" do
        TestSubscriber.routing_key_for(:created, "bar.foo")
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        expect(routing_key_name).to eq("bar.foo")
      end
    end

    context "when the routing key is not registered" do
      it "generates a routing key name" do
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        expect(routing_key_name).to eq("bob.test.created")
      end

      it "registers the generated routing key" do
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        expect(TestSubscriber.routing_key_names).to eq({:created => "bob.test.created"})
      end
    end
  end

  describe "subscribable methods" do
    it "returns the subscribable methods" do
      expect(TestSubscriber.subscribable_methods).to eq([:updated])
    end
  end
end
