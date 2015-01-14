require 'spec_helper'

class SeatacSubscriber < ActionSubscriber::Base
  at_most_once!
  publisher :tenderlove

  def stuck_out_tongue
    $messages_received += 1
    raise "Woops" if $messages_received < 3
  end
end

describe "A Subscriber in at_most_once! mode", :integration => true do
  let(:routes) { ActionSubscriber::DefaultRouter.routes_for_class(SeatacSubscriber) }

  it "only acknowledges after successfully processing them, errors are retried from the broker" do
    $messages_received = 0
    @subscription_set.start

    connection = ActionSubscriber::RabbitConnection.new_connection
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("Grump Face", :routing_key => "tenderlove.seatac.stuck_out_tongue")
    sleep 0.1
    connection.close

    expect($messages_received).to eq(1)
  end
end
