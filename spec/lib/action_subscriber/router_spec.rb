describe ActionSubscriber::Router do
  it "can specify basic routes" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :foo
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.routing_key).to eq("fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.foo")
  end

  it "can specify a publisher" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :bluff, :publisher => :amigo
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:bluff)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.routing_key).to eq("amigo.fake.bluff")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.amigo.fake.bluff")
  end

  it "can specify an exchange" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :crashed, :exchange => :actions
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:crashed)
    expect(routes.first.exchange).to eq("actions")
    expect(routes.first.routing_key).to eq("fake.crashed")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.crashed")
  end

  it "can specify acknowledgements" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :acknowledgements => true
    end

    expect(routes.first.acknowledgements).to eq(true)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.routing_key).to eq("fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.fake.foo")
  end

  it "can specify the queue" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :publisher => "russell", :queue => "i-am-your-father"
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.routing_key).to eq("russell.fake.foo")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("i-am-your-father")
  end

  it "can specify the routing key" do
    class FakeSubscriber; end

    routes = described_class.draw_routes do
      route FakeSubscriber, :foo, :publisher => "russell", :routing_key => "make.it.so"
    end

    expect(routes.first.acknowledgements).to eq(false)
    expect(routes.first.action).to eq(:foo)
    expect(routes.first.exchange).to eq("events")
    expect(routes.first.routing_key).to eq("make.it.so")
    expect(routes.first.subscriber).to eq(FakeSubscriber)
    expect(routes.first.queue).to eq("alice.russell.fake.foo")
  end
end
