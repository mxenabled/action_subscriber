class PrankSubscriber < ActionSubscriber::Base
  publisher :pikitis

  def pulled
    $messages << env.headers
  end
end

describe "Custom Headers Are Published and Received", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for PrankSubscriber
    end
  end
  let(:headers) { { "Custom" => "content/header" } }
  
  it "passes custom headers through" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("pikitis.prank.pulled", "Yo Knope!", "events", :headers => headers)
    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new([headers]))
    end
  end
end
