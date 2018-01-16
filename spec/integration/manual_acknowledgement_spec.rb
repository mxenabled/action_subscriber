class BaconSubscriber < ActionSubscriber::Base
  manual_acknowledgement!

  def served
    $messages << "#{payload}::#{$messages.size}"
    if $messages.size > 3
      acknowledge
    elsif $messages.size > 2
      nack
    else
      reject
    end
  end
end

describe "Manual Message Acknowledgment", :integration => true do
  let(:connection) { subscriber.connection }
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for BaconSubscriber
    end
  end
  let(:subscriber) { BaconSubscriber }

  it "retries rejected/nacked messages and stops retrying acknowledged messages" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("bacon.served", "BACON!", "events")

    verify_expectation_within(2.5) do
      expect($messages).to eq(Set.new(["BACON!::0", "BACON!::1", "BACON!::2", "BACON!::3"]))
    end
  end
end
