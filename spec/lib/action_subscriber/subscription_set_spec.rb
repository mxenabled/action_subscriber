require 'spec_helper'

class DogSubscriber
end

describe ActionSubscriber::SubscriptionSet do
  let(:route) {
    ActionSubscriber::Route.new(
      :action => :created,
      :exchange => "events",
      :queue => "dog.created",
      :routing_key => "bob.dog.created",
      :subscriber => DogSubscriber,
    )
  }
  let(:routes) { [route] }

  it "sets up a subscription" do
    
  end
end
