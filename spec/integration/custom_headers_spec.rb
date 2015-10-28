class PrankSubscriber < ActionSubscriber::Base
  publisher :pikitis

  def pulled
    $messages << env.headers
  end
end

describe "Custom Headers Are Published and Received", :integration => true do
  let(:headers) { { "Custom" => "content/header" } }

  it "works for auto_pop!" do
    ::ActionSubscriber::Publisher.publish("pikitis.prank.pulled", "Yo Knope!", "events", :headers => headers)
    verify_expectation_within(2.0) do
      ::ActionSubscriber.auto_pop!
      expect($messages).to eq(Set.new([headers]))
    end
  end

  it "works for auto_subscriber!" do
    ::ActionSubscriber.auto_subscribe!
    ::ActionSubscriber::Publisher.publish("pikitis.prank.pulled", "Yo Knope!", "events", :headers => headers)
    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new([headers]))
    end
  end
end
