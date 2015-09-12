class PokemonSubscriber < ActionSubscriber::Base
  at_most_once!

  def caught_em_all
    $messages << "DONE::#{$messages.size}"
    raise RuntimeError.new("what do I do now?")
  end
end

describe "at_most_once! mode", :integration => true do
  let(:connection) { subscriber.connection }
  let(:subscriber) { PokemonSubscriber }

  it "does not retry a failed message" do
    ::ActionSubscriber.auto_subscribe!
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("All Pokemon have been caught", :routing_key => "pokemon.caught_em_all")

    verify_expectation_within(1.0) do
      expect($messages.size).to eq 1
    end
  end
end
