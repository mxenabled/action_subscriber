require "spec_helper"
require "rabbitmq/http/client"

class YoloSubscriber < ActionSubscriber::Base
  def created
    $messages << payload
  end
end

describe "Automatically handles consumer cancellation", :integration => true, :slow => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      default_routes_for ::YoloSubscriber
    end
  end
  let(:http_client) { ::RabbitMQ::HTTP::Client.new("http://127.0.0.1:15672") }
  let(:subscriber) { ::YoloSubscriber }

  it "resubscribes on cancellation" do
    ::ActionSubscriber::start_subscribers!
    ::ActivePublisher.publish("yolo.created", "First", "events")
    verify_expectation_within(5.0) do
      expect($messages).to eq(::Set.new(["First"]))
    end

    consumers = rabbit_consumers.dup

    # Signal a cancellation event to all subscribers.
    delete_all_queues!

    # Give consumers a chance to restart.
    sleep 2.0

    expect(rabbit_consumers).to_not eq(consumers)

    ::ActivePublisher.publish("yolo.created", "Second", "events")
    verify_expectation_within(5.0) do
      expect($messages).to eq(Set.new(["First", "Second"]))
    end
  end

  context "when resubscribe on consumer cancellation is disabled" do
    before do
      allow(::ActionSubscriber.configuration).to receive(:resubscribe_on_consumer_cancellation).and_return(false)
    end

    it "does not resubscribe on cancellation" do
      ::ActionSubscriber::start_subscribers!
      ::ActivePublisher.publish("yolo.created", "First", "events")
      verify_expectation_within(5.0) do
        expect($messages).to eq(::Set.new(["First"]))
      end

      consumers = rabbit_consumers.dup

      # Signal a cancellation event to all subscribers.
      delete_all_queues!

      # Give consumers a chance to restart.
      sleep 2.0

      # Verify the consumers did not change.
      expect(rabbit_consumers).to eq(consumers)

      ::ActivePublisher.publish("yolo.created", "Second", "events")

      # Force sleep 2 seconds to ensure a resubscribe did not happen and messages were not processed.
      sleep 2.0
      expect($messages).to eq(Set.new(["First"]))
    end
  end

  describe "resubscription logic" do
    let(:subscription) { subject.send(:subscriptions).first }
    subject { ::ActionSubscriber.send(:route_set) }

    it "sets up consumers" do
      if ::RUBY_PLATFORM == "java"
        expect { subject.safely_restart_subscriber(subscription) }.to change { subject.march_hare_consumers.count }.from(0).to(1)
      else
        expect { subject.safely_restart_subscriber(subscription) }.to change { subject.bunny_consumers.count }.from(0).to(1)
      end
    end

    context "when error is raised during resubscription process" do
      context "and error is one that can be retried" do
        let(:error) { ::RuntimeError.new("queue 're.created' in vhost '/' process is stopped by supervisor") }

        it "retries resubscription process" do
          expect(subject).to receive(:setup_queue).and_raise(error).ordered
          expect(subject).to receive(:setup_queue).and_raise(error).ordered
          expect(subject).to receive(:setup_queue).and_call_original.ordered
          expect(::ActionSubscriber.config.error_handler).to receive(:call).with(error).twice
          expect(::ActionSubscriber.logger).to receive(:error).twice
          expect(subject).to receive(:sleep).twice # mostly to skip the delay
          subject.safely_restart_subscriber(subscription)
        end
      end

      context "and error is one that can't be retried" do
        let(:error) { ::RuntimeError.new("kaBOOM") }

        it "calls error handler and raises" do
          expect(subject).to receive(:setup_queue).and_raise(error).ordered
          expect(::ActionSubscriber.config.error_handler).to receive(:call).with(error).once
          expect(subject).to_not receive(:sleep)
          expect { subject.safely_restart_subscriber(subscription) }.to raise_error(error)
        end
      end
    end
  end

  def rabbit_consumers
    route_set = ::ActionSubscriber.send(:route_set)
    route_set.try(:bunny_consumers) || route_set.try(:march_hare_consumers)
  end

  def delete_all_queues!
    http_client.list_queues.each do |queue|
      http_client.delete_queue(queue.vhost, queue.name)
    end
  end
end
