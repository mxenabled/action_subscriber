describe ::ActionSubscriber::Middleware::ResubscribeHandler do
  describe "#call" do
    let(:app) { lambda { |_| true } }
    let(:consumer1) { double("consumer1") }
    let(:consumer2) { double("consumer2") }
    let(:consumers) { [consumer1, consumer2] }
    let(:env) {
      ::ActionSubscriber::Middleware::ResubscribeEnv.new(
        {
          :consumer => consumer1,
          :consumers => consumers,
          :route_set => route_set,
          :subscription => subscription
        }
      )
    }
    let(:new_queue) { double("new queue") }
    let(:queue) { double("queue", :name => "some.queue") }
    let(:route) { instance_double("::ActionSubscriber::Route") }
    let(:route_set) { instance_double("::ActionSubscriber::RouteSet") }
    let(:subscription) {
      {
        :queue => queue,
        :route => route,
      }
    }
    subject { described_class.new(app) }

    it "removes consumer from list and sets up new queue" do
      expect(queue).to receive_message_chain(:channel, :close)
      expect(route_set).to receive(:setup_queue).with(route).and_return(new_queue)
      expect(route_set).to receive(:start_subscriber_for_subscription).with(subscription)

      subject.call(env)

      expect(consumers).to eq [consumer2]
      expect(subscription[:queue]).to eq(new_queue)
    end
  end
end
