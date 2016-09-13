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

  context "ActionSubscriber.auto_pop!" do
    it "routes messages to the right place" do
      ::ActivePublisher.publish("basic_push.booked", "Ohai Booked", "events")

      verify_expectation_within(2.0) do
        ::ActionSubscriber.auto_pop!
        expect($messages).to eq(Set.new(["Ohai Booked"]))
      end
    end
  end

  context "ActionSubscriber.auto_subscribe!" do
    it "routes messages to the right place" do
      ::ActionSubscriber.auto_subscribe!
      ::ActivePublisher.publish("basic_push.booked", "Ohai Booked", "events")

      verify_expectation_within(2.0) do
        expect($messages).to eq(Set.new(["Ohai Booked"]))
      end
    end
  end
end
