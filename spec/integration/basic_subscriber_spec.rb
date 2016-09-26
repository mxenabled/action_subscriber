class BasicPushSubscriber < ActionSubscriber::Base
  def booked
    $messages << payload
  end
end

describe "A Basic Subscriber", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      route ::BasicPushSubscriber, :booked
    end
  end

  it "routes messages to the right place" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("basic_push.booked", "Ohai Booked", "events")

    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new(["Ohai Booked"]))
    end
  end
end
