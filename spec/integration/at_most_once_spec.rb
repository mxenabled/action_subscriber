class PokemonSubscriber < ActionSubscriber::Base
  at_most_once!

  def caught_em_all
    $messages << "DONE::#{$messages.size}"
    raise RuntimeError.new("what do I do now?")
  end
end

class PokemonWithAroundSubscriber < ActionSubscriber::Base
  around_filter :catch_you_first
  at_most_once!

  def caught_em_all
    raise RuntimeError.new("what do I do now?")
  end

  private

  def catch_you_first
    $messages << "DONE::#{$messages.size}"
    raise RuntimeError.new("caught you first")
  end
end

describe "at_most_once! mode", :integration => true do
  context "without overriding around_filter" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        default_routes_for PokemonSubscriber
      end
    end
    let(:subscriber) { PokemonSubscriber }

    it "does not retry a failed message" do
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("pokemon.caught_em_all", "All Pokemon have been caught", "events")

      verify_expectation_within(1.0) do
        expect($messages.size).to eq 1
      end
    end
  end

  context "with overriding around_filter" do
    let(:draw_routes) do
      ::ActionSubscriber.draw_routes do
        default_routes_for PokemonWithAroundSubscriber
      end
    end
    let(:subscriber) { PokemonWithAroundSubscriber }

    it "does not retry a failed message" do
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("pokemon_with_around.caught_em_all", "All Pokemon have been caught", "events")

      verify_expectation_within(1.0) do
        expect($messages.size).to eq 1
      end
    end
  end
end
