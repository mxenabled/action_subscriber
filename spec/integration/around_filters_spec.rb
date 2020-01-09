class InstaSubscriber < ActionSubscriber::Base
  around_filter :whisper
  around_filter :yell
  around_filter :whisper
  around_filter :whisper
  around_filter :yell

  def first
    $messages << payload
  end

  private

  def whisper
    $messages << :whisper_before
    yield
    $messages << :whisper_after
  end

  def yell
    $messages << :yell_before
    yield
    $messages << :yell_after
  end
end

describe "subscriber filters", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for InstaSubscriber
    end
  end
  let(:subscriber) { InstaSubscriber }

  it "does not allow an around filter to be pushed on twice" do
    expect(InstaSubscriber.around_filters.map(&:callback_method)).to eq([:whisper, :yell])
  end

  it "runs multiple around filters" do
    $messages = []  #testing the order of things
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("insta.first", "hEY Guyz!", "events")

    verify_expectation_within(1.0) do
      expect($messages).to eq [:whisper_before, :yell_before, "hEY Guyz!", :yell_after, :whisper_after]
    end
  end
end

class OptionsSubscriber < ActionSubscriber::Base
  around_filter :whisper, :if => [:primero, :segundo]
  around_filter :yell, :if => [:primero]
  around_filter :gossip, :unless => [:private_action]
  around_filter :everybody

  def primero
    $messages << payload
  end

  def private_action
    $messages << payload
  end

  def segundo
    $messages << payload
  end

  private

  def everybody
    $messages << :everybody_before
    yield
    $messages << :everybody_after
  end

  def gossip
    $messages << :gossip_before
    yield
    $messages << :gossip_after
  end

  def whisper
    $messages << :whisper_before
    yield
    $messages << :whisper_after
  end

  def yell
    $messages << :yell_before
    yield
    $messages << :yell_after
  end
end

describe "subscriber filters with conditions", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for OptionsSubscriber
    end
  end
  let(:subscriber) { OptionsSubscriber }

  context "honors conditions" do
    it "runs yell" do
      $messages = []
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("options.primero", "Howdy!", "events")

      verify_expectation_within(1.0) do
        expect($messages).to eq [:whisper_before, :yell_before, :gossip_before, :everybody_before, "Howdy!", :everybody_after, :gossip_after, :yell_after, :whisper_after]
      end
    end

    it "doesn't yell" do
      $messages = []
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("options.segundo", "Howdy!", "events")

      verify_expectation_within(1.0) do
        expect($messages).to eq [:whisper_before, :gossip_before, :everybody_before, "Howdy!", :everybody_after, :gossip_after, :whisper_after]
      end
    end

    it "doesn't gossip" do
      $messages = []
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("options.private_action", "Howdy!", "events")

      verify_expectation_within(1.0) do
        expect($messages).to eq [:everybody_before, "Howdy!", :everybody_after]
      end
    end
  end
end
