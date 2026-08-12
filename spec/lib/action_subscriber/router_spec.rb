describe ActionSubscriber::Router do
  class FakeSubscriber; end

  it "can specify basic routes" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.foo")
  end

  it "can specify a publisher" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :bluff, :publisher => :amigo
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:bluff)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("amigo.fake.bluff")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.amigo.fake.bluff")
  end

  it "can specify an exchange" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :crashed, :exchange => :actions
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:crashed)
    expect(routes.first.exchange).to eq("actions")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("fake.crashed")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.crashed")
  end

  it "can specify acknowledgements" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :acknowledgements => true
    end

    expect(routes.first.acknowledgements).to eq(true)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.foo")
  end

  it "defers to the broker by default" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo
    end

    expect(routes.first.queue_type).to be_nil
    expect(routes.first.driver_queue_type).to be_nil
  end

  it "accepts :broker_default as an explicit alias for nil" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :queue_type => :broker_default
    end

    expect(routes.first.queue_type).to be_nil
    expect(routes.first.driver_queue_type).to be_nil
  end

  it "can specify a queue type" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :queue_type => :classic
    end

    expect(routes.first.queue_type).to eq(:classic)
    expect(routes.first.driver_queue_type).to eq("classic")
    expect(routes.first.durable).to eq(false)
  end

  it "forces quorum queues to be durable" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :queue_type => :quorum
    end

    expect(routes.first.queue_type).to eq(:quorum)
    expect(routes.first.durable).to eq(true)
  end

  it "inherits the queue type from the global configuration" do
    allow(ActionSubscriber.config).to receive(:queue_type).and_return(:quorum)

    routes = described_class.draw_routes do
      route FakeSubscriber, :foo
    end

    expect(routes.first.queue_type).to eq(:quorum)
  end

  it "can specify a queue is durable" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :durable => true
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(true)
    expect(routes.first.routing_key).to eq("fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.foo")
  end

  describe "durability" do
    context "with a global durable setting", :as_config => { :durable => true } do
      it "is inherited by a route that does not name durability" do
        routes = described_class.draw_routes do
          route FakeSubscriber, :foo
        end

        expect(routes.first.durable).to eq(true)
      end

      # The distinction Router::DEFAULT_SETTINGS used to erase: an unspecified route has
      # to be told apart from one that explicitly asked for false.
      it "can be opted out of per route" do
        routes = described_class.draw_routes do
          route FakeSubscriber, :foo, :durable => false
        end

        expect(routes.first.durable).to eq(false)
      end
    end

    context "with a subscriber that declares durability" do
      class DurableDeclaringSubscriber < ::ActionSubscriber::Base
        durable true
        def foo; end
      end

      class TransientDeclaringSubscriber < ::ActionSubscriber::Base
        durable false
        def foo; end
      end

      it "beats the global configuration" do
        routes = described_class.draw_routes do
          route DurableDeclaringSubscriber, :foo
        end

        expect(routes.first.durable).to eq(true)
      end

      it "applies to default_routes_for as well" do
        routes = described_class.draw_routes do
          default_routes_for DurableDeclaringSubscriber
        end

        expect(routes.first.durable).to eq(true)
      end

      it "loses to an explicit route option" do
        routes = described_class.draw_routes do
          route DurableDeclaringSubscriber, :foo, :durable => false
        end

        expect(routes.first.durable).to eq(false)
      end

      it "can pin a subscriber transient against a global durable setting", :as_config => { :durable => true } do
        routes = described_class.draw_routes do
          route TransientDeclaringSubscriber, :foo
        end

        expect(routes.first.durable).to eq(false)
      end

      # Quorum queues only exist as durable queues, so this is not overridable.
      it "cannot make a quorum route transient" do
        routes = described_class.draw_routes do
          route TransientDeclaringSubscriber, :foo, :queue_type => :quorum
        end

        expect(routes.first.durable).to eq(true)
      end
    end
  end

  it "can specify a prefetch value" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :acknowledgements => true, :prefetch => 10
      route FakeSubscriber, :bar, :acknowledgements => true
    end

    expect(routes.first.prefetch).to eq(10)
    expect(routes.last.prefetch).to eq(::ActionSubscriber.config.prefetch)
  end

  it "can specify the queue" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :publisher => "russell", :queue => "i-am-your-father"
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("russell.fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("i-am-your-father")
  end

  it "can specify the routing key" do
    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :publisher => "russell", :routing_key => "make.it.so"
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("make.it.so")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.russell.fake.foo")
  end

  it "can infer routes based on the default routing rules" do
    class SparkleSubscriber < ::ActionSubscriber::Base
      at_most_once!
      publisher :tommy
      exchange :party

      def bright; end
      def dim; end
    end

    routes = described_class.draw_routes do
      default_routes_for SparkleSubscriber
    end

    expect(routes.size).to eq(2)
    expect(routes.first.acknowledgements).to eq(true)
    expect(routes.first.action).to eq(:bright)
    expect(routes.first.exchange).to eq("party")
    expect(routes.first.durable).to eq(false)
    expect(routes.first.routing_key).to eq("tommy.sparkle.bright")
    expect(routes.first.subscriber).to eq(SparkleSubscriber)
    expect(routes.first.queue).to eq("alice.tommy.sparkle.bright")
    expect(routes.last.acknowledgements).to eq(true)
    expect(routes.last.action).to eq(:dim)
    expect(routes.last.exchange).to eq("party")
    expect(routes.last.durable).to eq(false)
    expect(routes.last.routing_key).to eq("tommy.sparkle.dim")
    expect(routes.last.subscriber).to eq(SparkleSubscriber)
    expect(routes.last.queue).to eq("alice.tommy.sparkle.dim")
  end
end
