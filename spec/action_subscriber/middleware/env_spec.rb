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

  its(:action){ should eq 'created' }
  its(:content_type){ should eq(properties[:content_type]) }
  its(:exchange){ should eq(properties[:exchange]) }
  its(:message_id){ should eq(properties[:message_id]) }
  its(:routing_key){ should eq(properties[:routing_key]) }

  describe "#to_hash" do
    it "includes the action" do
      subject.to_hash.should have_key(:action)
    end

    it "includes the content_type" do
      subject.to_hash.should have_key(:content_type)
    end

    it "includes the exchange" do
      subject.to_hash.should have_key(:exchange)
    end

    it "includes the routing_key" do
      subject.to_hash.should have_key(:routing_key)
    end

    it "includes the payload" do
      subject.to_hash.should have_key(:payload)
    end
  end
end
