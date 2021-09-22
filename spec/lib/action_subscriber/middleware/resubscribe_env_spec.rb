describe ActionSubscriber::Middleware::ResubscribeEnv do
  let(:consumer) { instance_double("::Bunny::Consumer") }
  let(:consumers) { [consumer] }
  let(:properties){
    {
      :consumer => consumer,
      :consumers => consumers,
      :route_set => route_set,
      :subscription => subscription,
    }
  }
  let(:route_set) { instance_double("::ActionSubscriber::RouteSet") }
  let(:subscription) { { :foo => "bar" } }
  subject { described_class.new(properties) }

  specify { expect(subject.consumer).to eq(consumer) }
  specify { expect(subject.consumers).to eq(consumers) }
  specify { expect(subject.route_set).to eq(route_set) }
  specify { expect(subject.subscription).to eq(subscription) }
end
