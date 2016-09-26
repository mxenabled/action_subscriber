class TwitterSubscriber < ActionSubscriber::Base
  def tweet
    $messages << {
      :decoded => payload,
      :raw => raw_payload,
    }
  end
end


describe "Payload Decoding", :integration => true do
  let(:connection) { subscriber.connection }
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for TwitterSubscriber
    end
  end
  let(:subscriber) { TwitterSubscriber }
  let(:json_string) { '{"foo": "bar"}' }

  it "decodes json by default" do
    ::ActionSubscriber.start_subscribers!
    ::ActivePublisher.publish("twitter.tweet", json_string, "events", :content_type => "application/json")

    verify_expectation_within(2.0) do
      expect($messages).to eq Set.new([{
        :decoded => JSON.parse(json_string),
        :raw => json_string,
      }])
    end
  end

  context "Custom Decoder" do
    let(:content_type) { "foo/type" }

    before { ::ActionSubscriber.config.add_decoder(content_type => lambda{ |payload| :foo }) }
    after { ::ActionSubscriber.config.decoder.delete(content_type) }

    it "it decodes the payload using the custom decoder" do
      ::ActionSubscriber.start_subscribers!
      ::ActivePublisher.publish("twitter.tweet", json_string, "events", :content_type => content_type)

      verify_expectation_within(2.0) do
        expect($messages).to eq Set.new([{
          :decoded => :foo,
          :raw => json_string,
        }])
      end
    end
  end
end
