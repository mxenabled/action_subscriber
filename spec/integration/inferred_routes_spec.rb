class InferenceSubscriber < ActionSubscriber::Base
  publisher :kyle

  def yo
    $messages << payload
  end

  queue_for :hey, "some_other_queue.hey"
  routing_key_for :hey, "other_routing_key.hey"
  def hey
    $messages << payload
  end
end

describe "A Subscriber With Inferred Routes", :integration => true do
  context "explicit routing with default_routes_for helper" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        default_routes_for InferenceSubscriber
      end
    end

    it "registers the routes and sets up the queues" do
      ::ActionSubscriber.auto_subscribe!
      ::ActivePublisher.publish("kyle.inference.yo", "YO", "events")
      ::ActivePublisher.publish("other_routing_key.hey", "HEY", "events")

      verify_expectation_within(2.0) do
        expect($messages).to eq(Set.new(["YO","HEY"]))
      end
    end
  end

  # This is the deprecated behavior we want to keep until version 2.0
  context "no explicit routes" do
    it "registers the routes and sets up the queues" do
      ::ActionSubscriber.auto_subscribe!
      ::ActivePublisher.publish("kyle.inference.yo", "YO", "events")
      ::ActivePublisher.publish("other_routing_key.hey", "HEY", "events")

      verify_expectation_within(2.0) do
        expect($messages).to eq(Set.new(["YO","HEY"]))
      end
    end
  end
end
