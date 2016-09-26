class GorbyPuffSubscriber < ActionSubscriber::Base
  at_least_once!

  def grumpy
    $messages << "#{payload}::#{$messages.size}"
    raise RuntimeError.new("what do I do now?") unless $messages.size > 2
  end
end

describe "at_least_once! mode", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for GorbyPuffSubscriber
    end
  end
  let(:subscriber) { GorbyPuffSubscriber }

  it "retries a failed job until it succeeds" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("gorby_puff.grumpy", "GrumpFace", "events")

    verify_expectation_within(2.0) do
      expect($messages).to eq Set.new(["GrumpFace::0","GrumpFace::1","GrumpFace::2"])
    end
  end
end
