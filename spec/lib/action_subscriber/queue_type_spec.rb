describe ActionSubscriber::QueueType do
  describe ".normalize" do
    it "treats nil and blank strings as the broker default" do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize("")).to be_nil
      expect(described_class.normalize("  ")).to be_nil
    end

    it "treats :broker_default as an alias for nil" do
      expect(described_class.normalize(:broker_default)).to be_nil
      expect(described_class.normalize("broker_default")).to be_nil
    end

    it "accepts strings and symbols for the supported types" do
      expect(described_class.normalize("classic")).to eq(:classic)
      expect(described_class.normalize(:quorum)).to eq(:quorum)
      expect(described_class.normalize("STREAM")).to eq(:stream)
    end

    it "raises on an unsupported type" do
      expect { described_class.normalize(:mirrored) }.to raise_error(ArgumentError, /unsupported queue_type/)
    end
  end

  describe ".driver_option" do
    # nil is what keeps x-queue-type off the wire in both bunny and march_hare.
    it "is nil for the broker default" do
      expect(described_class.driver_option(nil)).to be_nil
    end

    it "is the type name for an explicit type" do
      expect(described_class.driver_option(:quorum)).to eq("quorum")
      expect(described_class.driver_option(:classic)).to eq("classic")
    end
  end

  describe ".always_durable?" do
    it "is true for quorum and stream queues" do
      expect(described_class.always_durable?(:quorum)).to eq(true)
      expect(described_class.always_durable?(:stream)).to eq(true)
    end

    it "is false for classic and broker default queues" do
      expect(described_class.always_durable?(:classic)).to eq(false)
      expect(described_class.always_durable?(nil)).to eq(false)
    end
  end

  describe ".durable?" do
    it "honors the request for types that can be either" do
      expect(described_class.durable?(:classic, true)).to eq(true)
      expect(described_class.durable?(:classic, false)).to eq(false)
      expect(described_class.durable?(nil, false)).to eq(false)
    end

    it "forces durability for types that only exist as durable queues" do
      expect(described_class.durable?(:quorum, false)).to eq(true)
      expect(described_class.durable?(:stream, false)).to eq(true)
    end

    it "always answers with a boolean" do
      expect(described_class.durable?(nil, nil)).to eq(false)
    end
  end

  # These examples assign the global setting; :as_config puts it back.
  describe "configuration", :as_config => { :queue_type => nil } do
    it "defaults to nil" do
      expect(ActionSubscriber.config.queue_type).to be_nil
    end

    it "normalizes on assignment so readers always see a symbol or nil" do
      ActionSubscriber.config.queue_type = "quorum"
      expect(ActionSubscriber.config.queue_type).to eq(:quorum)

      ActionSubscriber.config.queue_type = :broker_default
      expect(ActionSubscriber.config.queue_type).to be_nil
    end

    it "raises at the point the bad value is set" do
      expect { ActionSubscriber.config.queue_type = "qourum" }.to raise_error(ArgumentError, /unsupported queue_type/)
    end
  end

  # The behavior this whole module exists for: march_hare reads its :type option
  # with fetch(:type, ... CLASSIC), so omitting the key declares a classic queue
  # while passing an explicit nil leaves x-queue-type off the wire.
  if ::RUBY_PLATFORM == "java"
    describe "march_hare integration" do
      def arguments_for(type)
        ::MarchHare::Queue.new(nil, "test.queue", :durable => false, :type => type).arguments
      end

      it "sends no x-queue-type when the driver option is nil" do
        expect(arguments_for(described_class.driver_option(nil))).to eq({})
      end

      it "sends x-queue-type when a type is named" do
        expect(arguments_for(described_class.driver_option(:quorum))).to eq("x-queue-type" => "quorum")
      end

      it "would send classic if the :type key were omitted entirely" do
        omitted = ::MarchHare::Queue.new(nil, "test.queue", :durable => false).arguments
        expect(omitted).to eq("x-queue-type" => "classic")
      end
    end
  end
end
