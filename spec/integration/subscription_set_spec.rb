require 'spec_helper'

class DogSubscriber
  def initialize(env)
    @env = env
  end

  def created
    $messages << @env.payload
  end
end

describe ActionSubscriber::SubscriptionSet, :integration => true do
  let(:route) {
    ActionSubscriber::Route.new(
      :action => :created,
      :exchange => "events",
      :queue => "bob.dog.created",
      :routing_key => "dog.created",
      :subscriber => DogSubscriber,
    )
  }
  let(:routes) { [route] }

  it "sets up subscriptions which can be cleanly shut down" do
    @subscription_set.start

    connection = ActionSubscriber::RabbitConnection.new_connection
    channel = connection.channel
    exchange = channel.topic(route.exchange)
    exchange.publish("Dog Created", :routing_key => route.routing_key)
    exchange.publish("Another Dog Created", :routing_key => route.routing_key)

    sleep 0.1

    expect($messages).to eq(Set.new(["Dog Created", "Another Dog Created"]))
  end
end
