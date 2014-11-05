require 'spec_helper'

describe ActionSubscriber::Middleware::Env do
  let(:acknowledger) { double("acknowledger") }
  let(:encoded_payload) { 'encoded_payload' }
  let(:properties){ {
    :acknowledger => acknowledger,
    :content_type => "application/json",
    :encoded_payload => encoded_payload,
    :exchange => "events",
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
