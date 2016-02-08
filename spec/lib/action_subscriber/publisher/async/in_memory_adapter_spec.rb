describe ::ActionSubscriber::Publisher::Async::InMemoryAdapter do
  let(:route) { "test" }
  let(:payload) { "message" }
  let(:exchange_name) { "place" }
  let(:options) { { :test => :ok } }
  let(:message) { described_class::Message.new(route, payload, exchange_name, options) }
  let(:mock_queue) { double(:push => nil, :size => 0) }

  describe "#publish" do
    before do
      allow(described_class::Message).to receive(:new).with(route, payload, exchange_name, options).and_return(message)
      allow(described_class::AsyncQueue).to receive(:new).and_return(mock_queue)
    end

    it "can publish a message to the queue" do
      expect(mock_queue).to receive(:push).with(message)
      subject.publish(route, payload, exchange_name, options)
    end
  end

  describe "#shutdown!" do
    # This is called when the rspec finishes. I'm sure we can make this a better test.
  end

  describe "::ActionSubscriber::Publisher::Async::InMemoryAdapter::Message" do
    specify { expect(message.route).to eq(route) }
    specify { expect(message.payload).to eq(payload) }
    specify { expect(message.exchange_name).to eq(exchange_name) }
    specify { expect(message.options).to eq(options) }
  end

  describe "::ActionSubscriber::Publisher::Async::InMemoryAdapter::AsyncQueue" do
    subject { described_class::AsyncQueue.new }

    describe ".initialize" do
      it "creates a supervisor" do
        expect_any_instance_of(described_class::AsyncQueue).to receive(:create_and_supervise_consumer!)
        subject
      end
    end

    describe "#create_and_supervise_consumer!" do
      it "creates a supervisor" do
        expect_any_instance_of(described_class::AsyncQueue).to receive(:create_consumer)
        subject
      end

      it "restarts the consumer when it dies" do
        consumer = subject.consumer
        consumer.kill

        verify_expectation_within(0.1) do
          expect(consumer).to_not be_alive
        end

        verify_expectation_within(0.3) do
          expect(subject.consumer).to be_alive
        end
      end
    end

    describe "#create_consumer" do
      it "can successfully publish a message" do
        expect(::ActionSubscriber::Publisher).to receive(:publish).with(route, payload, exchange_name, options)
        subject.push(message)
        sleep 0.1 # Await results
      end

      context "when network error occurs" do
        let(:error) { described_class::AsyncQueue::NETWORK_ERRORS.first }
        before { allow(::ActionSubscriber::Publisher).to receive(:publish).and_raise(error) }

        it "requeues the message" do
          consumer = subject.consumer
          expect(consumer).to be_alive
          expect(subject).to receive(:await_network_reconnect).at_least(:once)
          subject.push(message)
          sleep 0.1 # Await results
        end
      end

      context "when an unknown error occurs" do
        before { allow(::ActionSubscriber::Publisher).to receive(:publish).and_raise(ArgumentError) }

        it "kills the consumer" do
          consumer = subject.consumer
          expect(consumer).to be_alive
          subject.push(message)
          sleep 0.1 # Await results
          expect(consumer).to_not be_alive
        end
      end
    end

    describe "#error_handler" do
      it "calls the error handler when something goes wrong" do
        expect(subject).to receive(:error_handler)
        subject.push(Object.new)
        sleep 0.1 # Await results
      end

      context "when an invalid custom error handler is provided" do
        let(:invalid_error_handler) { lambda {} }

        before { ::ActionSubscriber.configuration.async_publisher_error_handler = invalid_error_handler }
        after { ::ActionSubscriber.configuration.async_publisher_error_handler = ::ActionSubscriber::Configuration::DEFAULT_ERROR_HANDLER }

        it "returns nil" do
          expect(subject).to receive(:error_handler).and_return(nil)
          expect(subject.error_handler).to be_nil
        end
      end
    end

    describe "#push" do
      after { ::ActionSubscriber.configuration.async_publisher_max_queue_size = 1000 }
      after { ::ActionSubscriber.configuration.async_publisher_drop_messages_when_queue_full = false }

      context "when the queue has room" do
        before { allow(::Queue).to receive(:new).and_return(mock_queue) }

        it "successfully adds to the queue" do
          expect(mock_queue).to receive(:push).with(message)
          subject.push(message)
        end
      end

      context "when the queue is full" do
        before { ::ActionSubscriber.configuration.async_publisher_max_queue_size = -1 }

        context "and we're dropping messages" do
          before { ::ActionSubscriber.configuration.async_publisher_drop_messages_when_queue_full = true }

          it "adding to the queue should not raise an error" do
            expect { subject.push(message) }.to_not raise_error
          end
        end

        context "and we're not dropping messages" do
          before { ::ActionSubscriber.configuration.async_publisher_drop_messages_when_queue_full = false }

          it "adding to the queue should raise error back to caller" do
            expect { subject.push(message) }.to raise_error(described_class::UnableToPersistMessageError)
          end
        end
      end
    end

    describe "#size" do
      it "can return the size of the queue" do
        expect(subject.size).to eq(0)
      end
    end
  end
end
