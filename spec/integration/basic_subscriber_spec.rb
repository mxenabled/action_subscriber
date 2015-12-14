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
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for ::BasicPushSubscriber
    end
  end
  let(:subscriber) { BasicPushSubscriber }

  context "ActionSubscriber.auto_pop!" do
    it "routes messages to the right place" do
      ::ActionSubscriber::Publisher.publish("greg.basic_push.booked", "Ohai Booked", "events")
      ::ActionSubscriber::Publisher.publish("basic.cancelled", "Ohai Cancelled", "events")

      verify_expectation_within(2.0) do
        ::ActionSubscriber.auto_pop!
        expect($messages).to eq(Set.new(["Ohai Booked", "Ohai Cancelled"]))
      end
    end
  end

  context "ActionSubscriber.auto_subscribe!" do
    it "routes messages to the right place" do
      ::ActionSubscriber.auto_subscribe!
      ::ActionSubscriber::Publisher.publish("greg.basic_push.booked", "Ohai Booked", "events")
      ::ActionSubscriber::Publisher.publish("basic.cancelled", "Ohai Cancelled", "events")

      verify_expectation_within(2.0) do
        expect($messages).to eq(Set.new(["Ohai Booked", "Ohai Cancelled"]))
      end
    end
  end
end
