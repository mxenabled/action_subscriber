describe ::ActionSubscriber::Publisher do
  let(:exchange) { double("Rabbit Exchange") }
  let(:exchange_name) { "events" }
  let(:payload) { "Yo Dawg" }
  let(:route) { "bob.users.created" }

  before { allow(described_class).to receive(:with_exchange).with(exchange_name).and_yield(exchange) }

  describe '.publish' do

    if ::RUBY_PLATFORM == "java"
      it "publishes to the exchange with default options for march_hare" do
        expect(exchange).to receive(:publish) do |published_payload, published_options|
          expect(published_payload).to eq(payload)
          expect(published_options[:routing_key]).to eq(route)
          expect(published_options[:mandatory]).to eq(false)
          expect(published_options[:properties][:persistent]).to eq(false)
        end

        described_class.publish(route, payload, exchange_name)
      end
    else
      it "publishes to the exchange with default options for bunny" do
        expect(exchange).to receive(:publish) do |published_payload, published_options|
          expect(published_payload).to eq(payload)
          expect(published_options[:routing_key]).to eq(route)
          expect(published_options[:persistent]).to eq(false)
          expect(published_options[:mandatory]).to eq(false)
        end

        described_class.publish(route, payload, exchange_name)
      end
    end
  end
end
