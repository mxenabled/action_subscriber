# What actually landed on the broker is the only thing worth asserting here: the driver
# option and the wire arguments are already covered by the unit specs, and neither tells
# you whether the broker agreed. These read the queue back over the management API.

class QuorumQueueSubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

class ClassicQueueSubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

class BrokerDefaultQueueSubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

class ConflictingTypeSubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

describe "Queue types", :integration => true do
  let(:helper) { RabbitMQTestHelper }

  # A queue of the right type is only half the claim -- it also has to carry messages.
  shared_examples "a working subscription" do |routing_key, body|
    it "delivers messages" do
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish(routing_key, body, "events")

      verify_expectation_within(5.0) do
        expect($messages).to eq(Set.new([body]))
      end
    end
  end

  describe "a :quorum route" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        route ::QuorumQueueSubscriber, :created, :queue_type => :quorum
      end
    end
    let(:queue_name) { "alice.quorum_queue.created" }

    it "declares a durable quorum queue" do
      info = helper.queue_info(queue_name)

      expect(info.type).to eq("quorum")
      expect(info.durable).to eq(true)
    end

    it_behaves_like "a working subscription", "quorum_queue.created", "Ohai Quorum"
  end

  describe "a :quorum route declared with :durable => false" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        route ::QuorumQueueSubscriber, :created, :queue_type => :quorum, :durable => false
      end
    end

    # Route forces this rather than letting the broker refuse the declaration.
    it "is still durable" do
      expect(helper.queue_durable?("alice.quorum_queue.created")).to eq(true)
    end
  end

  describe "a :classic route" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        route ::ClassicQueueSubscriber, :created, :queue_type => :classic, :durable => true
      end
    end
    let(:queue_name) { "alice.classic_queue.created" }

    it "declares a classic queue" do
      expect(helper.queue_type_of(queue_name)).to eq("classic")
    end

    it_behaves_like "a working subscription", "classic_queue.created", "Ohai Classic"
  end

  describe "a :broker_default route" do
    # Named explicitly rather than left to the global setting, because CI runs the whole
    # suite with ACTION_SUBSCRIBER_QUEUE_TYPE set on some jobs. Durable so the
    # declaration is legal on a broker that denies transient non-exclusive queues.
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        route ::BrokerDefaultQueueSubscriber, :created, :queue_type => :broker_default, :durable => true
      end
    end
    let(:queue_name) { "alice.broker_default_queue.created" }

    # Sending no x-queue-type is what lets an operator move a vhost onto quorum queues
    # with a broker setting instead of a code change. On JRuby this is the whole point of
    # the :type => nil option -- march_hare would otherwise pin the queue to classic.
    it "gets whatever the vhost's default_queue_type is" do
      expect(helper.queue_type_of(queue_name)).to eq(helper.default_queue_type)
    end

    it_behaves_like "a working subscription", "broker_default_queue.created", "Ohai Default"
  end

  # The regression that motivated ActionSubscriber::QueueType. Master had no way to say
  # "quorum", so subscribing to a queue somebody else had declared as a durable quorum
  # queue could not work:
  #
  #   * on JRuby, march_hare filled in :type => "classic" for the omitted option and the
  #     broker rejected the redeclaration on x-queue-type;
  #   * on MRI, bunny sent no x-queue-type, which the broker resolves against the vhost's
  #     default_queue_type -- classic on a default vhost -- and rejected the same way;
  #   * and both sent durable => false, which a quorum queue rejects on its own.
  describe "subscribing to a queue that already exists as a durable quorum queue" do
    # A harmless route, so the suite-wide integration hook has something to set up. The
    # examples below drive setup_queue directly against the conflicting queue.
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        route ::QuorumQueueSubscriber, :created, :queue_type => :quorum
      end
    end
    let(:queue_name) { "alice.conflicting_type.created" }

    before do
      @opened_channels = []
      helper.delete_queue!(queue_name)
      helper.declare_queue!(queue_name, :durable => true, :type => "quorum")
    end

    after do
      # setup_queue opens a channel on the *shared* subscriber connection and never
      # closes it. Leaving them open leaks a consumer work pool per example and gives
      # later specs -- consumer_cancellation deletes every queue in the vhost -- more
      # channels on that connection to disturb.
      @opened_channels.each do |channel|
        begin
          channel.close
        rescue ::StandardError
          nil
        end
      end
      helper.delete_queue!(queue_name)
    end

    def setup_queue_for(route_options)
      routes = ::ActionSubscriber::Router.draw_routes do
        route ::ConflictingTypeSubscriber, :created, route_options
      end
      queue = ::ActionSubscriber::RouteSet.new(routes).send(:setup_queue, routes.first)
      @opened_channels << queue.channel
      queue
    end

    it "fails when the route does not name the type (what master always did)" do
      expect {
        setup_queue_for(:queue_type => :broker_default, :durable => true)
      }.to raise_error(/PRECONDITION_FAILED/)
    end

    it "fails when the route names a conflicting type" do
      expect {
        setup_queue_for(:queue_type => :classic, :durable => true)
      }.to raise_error(/PRECONDITION_FAILED/)
    end

    it "fails on durability alone when the route is transient" do
      # Reaches the broker as a durable mismatch on 3.x. On 4.x the transient
      # declaration is refused before that, which is its own kind of failure.
      expect {
        setup_queue_for(:queue_type => :broker_default, :durable => false)
      }.to raise_error(::StandardError)
    end

    it "succeeds when the route names :quorum" do
      queue = setup_queue_for(:queue_type => :quorum)

      expect(queue.name).to eq(queue_name)
      expect(helper.queue_type_of(queue_name)).to eq("quorum")
    end
  end
end
