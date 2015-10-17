describe ActionSubscriber::Middleware::Env do
  let(:channel) { double("channel") }
  let(:encoded_payload) { 'encoded_payload' }
  let(:properties){ {
    :channel => channel,
    :content_type => "application/json",
    :delivery_tag => "XYZ",
    :encoded_payload => encoded_payload,
    :exchange => "events",
    :headers => {},
    :message_id => "MSG-1234",
    :routing_key => "amigo.user.created",
  } }
  let(:subscriber) { UserSubscriber }

  subject { described_class.new(subscriber, encoded_payload, properties) }

  specify { expect(subject.action).to eq("created") }
  specify { expect(subject.content_type).to eq(properties[:content_type]) }
  specify { expect(subject.exchange).to eq(properties[:exchange]) }
  specify { expect(subject.message_id).to eq(properties[:message_id]) }
  specify { expect(subject.routing_key).to eq(properties[:routing_key]) }

  describe "#acknowledge" do
    it "sends an acknowledgement to rabbitmq" do
      expect(channel).to receive(:ack).with(properties[:delivery_tag], false)
      subject.acknowledge
    end
  end

  describe "#reject" do
    it "sends an rejection to rabbitmq" do
      expect(channel).to receive(:reject).with(properties[:delivery_tag], true)
      subject.reject
    end
  end

  describe "#to_hash" do
    it "includes the action" do
      expect(subject.to_hash).to have_key(:action)
    end

    it "includes the content_type" do
      expect(subject.to_hash).to have_key(:content_type)
    end

    it "includes the exchange" do
      expect(subject.to_hash).to have_key(:exchange)
    end

    it "includes the routing_key" do
      expect(subject.to_hash).to have_key(:routing_key)
    end

    it "includes the payload" do
      expect(subject.to_hash).to have_key(:payload)
    end
  end
end
