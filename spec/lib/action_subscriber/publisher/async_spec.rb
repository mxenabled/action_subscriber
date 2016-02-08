describe ::ActionSubscriber::Publisher::Async do

  before { described_class.instance_variable_set(:@publisher_adapter, nil) }
  after { ::ActionSubscriber.configuration.async_publisher = "memory" }

  let(:mock_adapter) { double(:publish => nil) }

  describe ".publish_async" do
    before { allow(described_class).to receive(:publisher_adapter).and_return(mock_adapter) }

    it "calls through the adapter" do
      expect(mock_adapter).to receive(:publish).with("1", "2", "3", { "four" => "five" })
      ::ActionSubscriber::Publisher.publish_async("1", "2", "3", { "four" => "five" })
    end
  end

  context "when an in-memory adapter is selected" do
    before { ::ActionSubscriber.configuration.async_publisher = "memory" }

    it "Creates an in-memory publisher" do
      expect(described_class.publisher_adapter).to be_an(::ActionSubscriber::Publisher::Async::InMemoryAdapter)
    end
  end

  context "when an redis adapter is selected" do
    before { ::ActionSubscriber.configuration.async_publisher = "redis" }

    it "raises an error" do
      expect { described_class.publisher_adapter }.to raise_error("Not yet implemented")
    end
  end

  context "when some random adapter is selected" do
    before { ::ActionSubscriber.configuration.async_publisher = "yolo" }

    it "raises an error" do
      expect { described_class.publisher_adapter }.to raise_error("Unknown adapter 'yolo' provided")
    end
  end
end
