require 'spec_helper'

describe ActionSubscriber::Middleware::Env do
  let(:header) { amqp_header(:events, 'app.user.created') }
  let(:encoded_payload) { 'encoded_payload' }
  let(:subscriber_class) { UserSubscriber }

  subject { described_class.new(subscriber_class, header, encoded_payload) }

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

  describe "#subscriber" do
    it "initializes a new subscriber" do
      subject.subscriber.should be_instance_of subscriber_class
    end
  end
end
