require 'spec_helper'

TestSubscriber = Class.new(ActionSubscriber::Base) do
  def updated
  end
end
TestSubscriber.remote_application_name :bob

describe ActionSubscriber::Router do
  describe "generate_queue_name" do
    it "returns a queue name" do
      queue_name = TestSubscriber.generate_queue_name(:created)
      queue_name.should eq("alice.bob.test.created")
    end
  end

  describe "generate_routing_key_name" do
    it "returns a routing key name" do
      routing_key_name = TestSubscriber.generate_routing_key_name(:created)
      routing_key_name.should eq("bob.test.created")
    end
  end

  describe "local_application_name" do
    it "returns the local application name" do
      TestSubscriber.local_application_name.should eq("alice")
    end
  end

  describe "queue_name_for_method" do
    before { TestSubscriber.instance_variable_set(:@_queue_names, nil) }

    context "when the queue is already registered" do
      it "returns the registered queue" do
        TestSubscriber.queue_for(:created, "foo.bar")
        queue_name = TestSubscriber.queue_name_for_method(:created)
        queue_name.should eq("foo.bar")
      end
    end

    context "when the queue is not registered" do
      it "generates a queue name" do
        queue_name = TestSubscriber.queue_name_for_method(:created)
        queue_name.should eq("alice.bob.test.created")
      end

      it "registers the generated queue" do
        queue_name = TestSubscriber.queue_name_for_method(:created)
        TestSubscriber.queue_names.should eq({:created =>"alice.bob.test.created"})
      end
    end
  end

  describe "resource_name" do
    it "returns the resource name" do
      TestSubscriber.resource_name.should eq("test")
    end
  end

  describe "routing_key_name_for_method" do
    before { TestSubscriber.instance_variable_set(:@_routing_key_names, nil) }

    context "when the routing key is already registered" do
      it "returns the registered routing key" do
        TestSubscriber.routing_key_for(:created, "bar.foo")
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        routing_key_name.should eq("bar.foo")
      end
    end

    context "when the routing key is not registered" do
      it "generates a routing key name" do
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        routing_key_name.should eq("bob.test.created")
      end

      it "registers the generated routing key" do
        routing_key_name = TestSubscriber.routing_key_name_for_method(:created)
        TestSubscriber.routing_key_names.should eq({:created => "bob.test.created"})
      end
    end
  end

  describe "subscribable methods" do
    it "returns the subscribable methods" do
      TestSubscriber.subscribable_methods.should eq([:updated])
    end
  end
end
