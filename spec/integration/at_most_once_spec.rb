class PokemonSubscriber < ActionSubscriber::Base
  at_most_once!

  def caught_em_all
    $messages << "DONE::#{$messages.size}"
    raise RuntimeError.new("what do I do now?")
  end
end

describe "at_most_once! mode", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for PokemonSubscriber
    end
  end
  let(:subscriber) { PokemonSubscriber }

  it "does not retry a failed message" do
    ::ActionSubscriber.auto_subscribe!
    ::ActivePublisher.publish("pokemon.caught_em_all", "All Pokemon have been caught", "events")

    verify_expectation_within(1.0) do
      expect($messages.size).to eq 1
    end
  end
end
