require 'spec_helper'

class DogSubscriber
  def initialize(env)
    @env = env
  end

  def created
    puts "created: #{@env.payload}"
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

  subject { described_class.new(routes) }

  before { $messages = Set.new }

  it "sets up subscriptions which can be cleanly shut down" do
    subject.start

    connection = ActionSubscriber::RabbitConnection.new_connection
    channel = connection.channel
    exchange = channel.topic(route.exchange)
    exchange.publish("Dog Created", :routing_key => route.routing_key)
    exchange.publish("Another Dog Created", :routing_key => route.routing_key)

    sleep 1.0

    expect($messages).to eq(Set.new(["Dog Created", "Another Dog Created"]))

    subject.stop
  end
end
