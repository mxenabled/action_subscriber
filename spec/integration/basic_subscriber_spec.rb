require 'spec_helper'

class BasicPushSubscriber < ActionSubscriber::Base
  publisher :greg

  # queue => alice.greg.basic_push.booked
  # routing_key => greg.basic_push.booked
  def booked
    $messages << payload
  end

  queue_for :cancelled, "basic.cancelled"
  routing_key_for :cancelled, "basic.cancelled"

  def cancelled
    $messages << payload
  end
end

describe "A Basic Subscriber", :integration => true do
  let(:connection) { subscriber.connection }
  let(:subscriber) { BasicPushSubscriber }

  context "ActionSubscriber.auto_pop!" do
    it "routes messages to the right place" do
      channel = connection.create_channel
      exchange = channel.topic("events")
      exchange.publish("Ohai Booked", :routing_key => "greg.basic_push.booked")
      exchange.publish("Ohai Cancelled", :routing_key => "basic.cancelled")

      ::ActionSubscriber.auto_pop!

      expect($messages).to eq(Set.new(["Ohai Booked", "Ohai Cancelled"]))
    end
  end

  context "ActionSubscriber.auto_subscribe!" do
    it "routes messages to the right place" do
      ::ActionSubscriber.auto_subscribe!
      channel = connection.create_channel
      exchange = channel.topic("events")
      exchange.publish("Ohai Booked", :routing_key => "greg.basic_push.booked")
      exchange.publish("Ohai Cancelled", :routing_key => "basic.cancelled")
      sleep 0.1

      expect($messages).to eq(Set.new(["Ohai Booked", "Ohai Cancelled"]))
    end
  end
end
