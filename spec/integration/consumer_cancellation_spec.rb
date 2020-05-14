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

 context "when recover on consumer cancellation is disabled" do
   before do
     allow(::ActionSubscriber.configuration).to receive(:recover_on_consumer_cancellation).and_return(false)
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

     # Force sleep 2 seconds to ensure a recovery did not happen and messages were not processed.
     sleep 2.0
     expect($messages).to eq(Set.new(["First"]))
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
