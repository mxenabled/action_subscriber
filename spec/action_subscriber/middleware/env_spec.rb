require 'spec_helper'

describe ActionSubscriber::Middleware::Env do
  let(:header) { amqp_header(:events, 'app.user.created') }
  let(:encoded_payload) { 'encoded_payload' }
  let(:subscriber) { UserSubscriber }

  subject { described_class.new(subscriber, header, encoded_payload) }

  describe "#action" do
    it "returns the action from the routing key" do
      subject.action.should eq 'created'
    end
  end

  describe "#content_type" do
    it "returns the content_type from the header" do
      subject.content_type.should eq header.content_type.to_s
    end
  end

  describe "#exchange" do
    it "returns the exchange from the header" do
      subject.exchange.should eq header.exchange
    end
  end

  describe "#message_id" do
    it "returns the message_id from the header" do
      subject.message_id.should eq header.message_id
    end
  end

  describe "#method" do
    it "returns the method from the header" do
      subject.method.should eq header.method
    end
  end

  describe "#routing_key" do
    it "returns the routing key from the header" do
      subject.routing_key.should eq header.routing_key
    end
  end

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

    it "includes the method" do
      subject.to_hash.should have_key(:method)
    end

    it "includes the routing_key" do
      subject.to_hash.should have_key(:routing_key)
    end

    it "includes the payload" do
      subject.to_hash.should have_key(:payload)
    end
  end
end
