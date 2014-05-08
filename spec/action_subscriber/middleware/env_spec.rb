require 'spec_helper'

describe ActionSubscriber::Middleware::Env do
  let(:delivery_info) { amqp_delivery_info(:routing_key => "app.user.created", :exchange => "events") }
  let(:message_properties) { amqp_properties(:message_id => "MSG-1234", :content_type => "application/json") }
  let(:encoded_payload) { 'encoded_payload' }
  let(:subscriber) { UserSubscriber }

  subject { described_class.new(subscriber, delivery_info, message_properties, encoded_payload) }

  describe "#action" do
    it "returns the action from the routing key" do
      subject.action.should eq 'created'
    end
  end

  describe "#content_type" do
    it "returns the content_type from the header" do
      subject.content_type.should eq message_properties.content_type.to_s
    end
  end

  describe "#exchange" do
    it "returns the exchange from the header" do
      subject.exchange.should eq delivery_info.exchange
    end
  end

  describe "#message_id" do
    it "returns the message_id from the header" do
      subject.message_id.should eq message_properties.message_id
    end
  end

  describe "#routing_key" do
    it "returns the routing key from the header" do
      subject.routing_key.should eq delivery_info.routing_key
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

    it "includes the routing_key" do
      subject.to_hash.should have_key(:routing_key)
    end

    it "includes the payload" do
      subject.to_hash.should have_key(:payload)
    end
  end
end
