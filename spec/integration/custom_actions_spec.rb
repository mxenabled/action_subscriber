class CustomActionSubscriber < ActionSubscriber::Base
  def wat
    $messages << payload
  end
end

describe "A subscriber with a custom action", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      route ::CustomActionSubscriber, :wat,
        :queue => "unrelated_to_the_action",
        :routing_key => "*.javascript_framework"
    end
  end

  it "routes the message to the selected action" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("react.javascript_framework", "Another?!?!", "events")

    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new(["Another?!?!"]))
    end
  end
end
