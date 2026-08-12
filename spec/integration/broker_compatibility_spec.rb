class BrokerCompatibilitySubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

class DurableCompatibilitySubscriber < ActionSubscriber::Base
  durable true

  def created
    $messages << payload
  end
end

# Pins the differences between the RabbitMQ series action_subscriber claims to support.
# CI runs this file against both (see .circleci/config.yml); the examples branch on what
# the broker actually permits rather than on its version, so a 3.x broker with the
# deprecated feature denied, or a 4.x broker with it permitted, still gets a true answer.
describe "Broker compatibility", :integration => true do
  let(:helper) { RabbitMQTestHelper }
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      route ::BrokerCompatibilitySubscriber, :created, :queue_type => :quorum
    end
  end

  # Guards against a CI job silently testing the wrong broker -- e.g. an image tag that
  # stopped resolving to the series the job name claims. Only enforced when CI says what
  # it expects.
  expected_major = RabbitMQTestHelper.env("EXPECTED_RABBITMQ_MAJOR") { |value| Integer(value) }
  if expected_major
    it "is running against the broker series CI selected" do
      expect(helper.broker_major).to eq(expected_major)
    end
  end

  describe "durable declarations" do
    %w[classic quorum].each do |type|
      it "works for a durable #{type} queue on every supported broker" do
        name = "alice.compat.durable.#{type}"
        helper.declare_queue!(name, :durable => true, :type => type)
        info = helper.queue_info(name)

        expect(info.type).to eq(type)
        expect(info.durable).to eq(true)

        helper.delete_queue!(name)
      end
    end
  end

  # action_subscriber's routes default to :durable => false, which makes every default
  # route a transient non-exclusive queue. That is `permitted_by_default` on RabbitMQ 3.x
  # and `denied_by_default` on 4.x, where the broker answers with a connection-level 541
  # INTERNAL_ERROR rather than a channel-level error -- so the failure takes the whole
  # connection down with it.
  describe "transient non-exclusive queues (action_subscriber's default route shape)" do
    let(:queue_name) { "alice.compat.transient" }

    after { helper.delete_queue!(queue_name) }

    # Declares through the same option mapping the drivers use, so these cannot pass
    # against a stale copy of it. Into `queue_name` rather than the route's own queue:
    # this file's subscription already declared that one, as quorum.
    def declare_route!(route)
      helper.declare_route_queue!(route, queue_name)
      helper.queue_info(queue_name)
    end

    it "declares if and only if the broker permits the deprecated feature" do
      if helper.transient_nonexcl_queues_permitted?
        helper.declare_queue!(queue_name, :durable => false, :type => "classic")

        expect(helper.queue_durable?(queue_name)).to eq(false)
      else
        expect {
          helper.declare_queue!(queue_name, :durable => false, :type => "classic")
        }.to raise_error(::StandardError)
      end
    end

    # The direct fix: config.durable, which an operator can set from the yaml file
    # without touching code. Unlike :quorum this leaves the queue type alone, so it is
    # the smaller change for an existing classic-queue deployment moving to 4.x.
    context "with config.durable on", :as_config => { :durable => true } do
      it "is sidestepped, without changing the queue type" do
        durable_route = ::ActionSubscriber::Router.draw_routes do
          route ::BrokerCompatibilitySubscriber, :created, :queue_type => :broker_default
        end.first

        expect(durable_route.durable).to eq(true)

        info = declare_route!(durable_route)
        expect(info.type).to eq(helper.default_queue_type)
        expect(info.durable).to eq(true)
      end
    end

    # And the same via the subscriber DSL rather than the global setting.
    it "is sidestepped by a subscriber declaring `durable true`" do
      declared_route = ::ActionSubscriber::Router.draw_routes do
        route ::DurableCompatibilitySubscriber, :created, :queue_type => :broker_default
      end.first

      expect(declared_route.durable).to eq(true)
      expect(declare_route!(declared_route).durable).to eq(true)
    end

    # The other first-party option: :quorum forces :durable => true on the route, so it
    # sidesteps the deprecated feature too. This is what the 4.x quorum CI job relies on.
    it "is sidestepped by :quorum, which forces the route durable" do
      # Not named `route`: a local by that name would shadow the DSL method inside the
      # draw_routes block.
      quorum_route = ::ActionSubscriber::Router.draw_routes do
        route ::BrokerCompatibilitySubscriber, :created, :queue_type => :quorum, :durable => false
      end.first

      expect(quorum_route.durable).to eq(true)
      expect(declare_route!(quorum_route).type).to eq("quorum")
    end
  end

  # MessageRetry declares its own queues, and does it with the global config.queue_type
  # rather than the route's. It has to produce a declaration the broker accepts on both
  # series and on both drivers -- bunny does not force durability for quorum the way
  # march_hare does, so this is the shape most likely to regress.
  describe "retry queues" do
    let(:queue_name) { "alice.compat.retry_target.retry_100" }

    after { helper.delete_queue!(queue_name) }

    def declare_retry_queue!
      helper.with_raw_channel do |channel|
        env = double(:channel => channel, :queue => "alice.compat.retry_target")
        ::ActionSubscriber::MessageRetry.with_exchange(env, 100, queue_name) { |_exchange| nil }
      end
    end

    # Each context pins both settings, not just the one it is about: CI runs this whole
    # file with one or the other turned on.
    context "with quorum configured", :as_config => { :queue_type => :quorum, :durable => false } do
      it "declares a durable quorum retry queue" do
        declare_retry_queue!
        info = helper.queue_info(queue_name)

        expect(info.type).to eq("quorum")
        expect(info.durable).to eq(true)
      end
    end

    # Retry queues are declared here rather than drawn as routes, so they have to pick
    # up config.durable on their own. Missed at first, and it only showed up as a
    # cascade of unrelated failures: the refused declaration takes down the connection.
    context "with config.durable on", :as_config => { :queue_type => nil, :durable => true } do
      it "declares a durable retry queue of the broker's default type" do
        declare_retry_queue!
        info = helper.queue_info(queue_name)

        expect(info.durable).to eq(true)
        expect(info.type).to eq(helper.default_queue_type)
      end
    end

    context "with nothing configured", :as_config => { :queue_type => nil, :durable => false } do
      # Retry queues are transient by default, so they inherit the same 4.x limitation
      # the default route shape has. Asserting it keeps the constraint visible instead of
      # surfacing as a mystery failure the first time somebody retries a message on 4.x.
      it "declares a transient retry queue only where transient queues are permitted" do
        if helper.transient_nonexcl_queues_permitted?
          declare_retry_queue!
          expect(helper.queue_durable?(queue_name)).to eq(false)
        else
          expect { declare_retry_queue! }.to raise_error(::StandardError)
        end
      end
    end
  end
end
