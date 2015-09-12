class BaconSubscriber < ActionSubscriber::Base
  manual_acknowledgement!

  def served
    $messages << "#{payload}::#{$messages.size}"
    if $messages.size > 2
      acknowledge
    else
      reject
    end
  end
end

describe "Manual Message Acknowledgment", :integration => true do
  let(:connection) { subscriber.connection }
  let(:subscriber) { BaconSubscriber }

  it "retries rejected messages and stops retrying acknowledged messages" do
    ::ActionSubscriber.auto_subscribe!
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("BACON!", :routing_key => "bacon.served")

    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new(["BACON!::0", "BACON!::1", "BACON!::2"]))
    end
  end
end
