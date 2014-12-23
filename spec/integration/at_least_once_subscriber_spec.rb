require 'spec_helper'

class GorbyPuffSubscriber < ActionSubscriber::Base
  at_least_once!
  publisher :tenderlove

  def made_a_face
    $messages_received += 1
    raise "Woops" if $messages_received < 3
  end
end

describe "A Subscriber in at_least_once! mode", :integration => true do
  let(:routes) { ActionSubscriber::DefaultRouter.routes_for_class(GorbyPuffSubscriber) }

  it "only acknowledges after successfully processing them, errors are retried from the broker" do
    $messages_received = 0
    @subscription_set.start

    connection = ActionSubscriber::RabbitConnection.new_connection
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("Grump Face", :routing_key => "tenderlove.gorby_puff.made_a_face")
    sleep 0.1
    connection.close

    expect($messages_received).to eq(3)
  end
end
