require 'spec_helper'

class BasicPushSubscriber < ActionSubscriber::Base
  publisher :greg

  # queue => alice.greg.basic_push.booked
  # routing_key => greg.basic_push.booked
  def booked
    $messages << [:booked, payload]
  end

  queue_for :cancelled, "basic.cancelled"
  routing_key_for :cancelled, "basic.cancelled"

  def cancelled
    $messages << [:cancelled, payload]
  end
end

describe "A Basic Subscriber using Push API", :integration => true do
  let(:routes) { ActionSubscriber::DefaultRouter.routes_for_class(BasicPushSubscriber) }

  it "messages are routed to the right place" do
    @subscription_set.start

    connection = ActionSubscriber::RabbitConnection.new_connection
    channel = connection.channel
    exchange = channel.topic("events")
    exchange.publish("Ohai Booked", :routing_key => "greg.basic_push.booked")
    exchange.publish("Ohai Cancelled", :routing_key => "basic.cancelled")

    sleep 0.1

    expect($messages).to eq(Set.new([
      [:booked, "Ohai Booked"],
      [:cancelled, "Ohai Cancelled"],
    ]))
  end
end
