require 'spec_helper'

class BasicPushSubscriber < ActionSubscriber::Base
  BOOKED_MESSAGES = []
  CANCELLED_MESSAGES = []

  publisher :greg

  # queue => alice.greg.basic_push.booked
  # routing_key => greg.basic_push.booked
  def booked
    BOOKED_MESSAGES << payload
  end

  queue_for :cancelled, "basic.cancelled"
  routing_key_for :cancelled, "basic.cancelled"

  def cancelled
    CANCELLED_MESSAGES << payload
  end
end

describe "A Basic Subscriber using Push API", :integration => true do
  let(:connection) { subscriber.connection }
  let(:subscriber) { BasicPushSubscriber }

  it "messages are routed to the right place" do
    ::ActionSubscriber.start_queues

    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("Ohai Booked", :routing_key => "greg.basic_push.booked")
    exchange.publish("Ohai Cancelled", :routing_key => "basic.cancelled")

    ::ActionSubscriber.auto_pop!

    expect(subscriber::BOOKED_MESSAGES).to eq(["Ohai Booked"])
    expect(subscriber::CANCELLED_MESSAGES).to eq(["Ohai Cancelled"])

    connection.close
  end
end
