class GorbyPuffSubscriber < ActionSubscriber::Base
  at_least_once!

  def grumpy
    $messages << "#{payload}::#{$messages.size}"
    raise RuntimeError.new("what do I do now?") unless $messages.size > 2
  end
end

describe "at_least_once! mode", :integration => true do
  let(:connection) { subscriber.connection }
  let(:subscriber) { GorbyPuffSubscriber }

  it "retries a failed job until it succeeds" do
    ::ActionSubscriber.auto_subscribe!
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("GrumpFace", :routing_key => "gorby_puff.grumpy")

    verify_expectation_within(1.0) do
      expect($messages).to eq Set.new(["GrumpFace::0","GrumpFace::1","GrumpFace::2"])
    end
  end
end
