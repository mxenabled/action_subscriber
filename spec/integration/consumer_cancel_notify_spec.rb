require "rabbitmq/http/client"

class ZombieSubscriber < ActionSubscriber::Base
  def groan
    $messages << payload
  end
end

describe "Rebuilds subscription after receiving consumer_cancel_notify", :integration => true, :slow => true do
 let(:draw_routes) do
   ::ActionSubscriber.draw_routes do
     default_routes_for ZombieSubscriber
   end
 end
 let(:http_client) { RabbitMQ::HTTP::Client.new("http://127.0.0.1:15672") }
 let(:subscriber) { ZombieSubscriber }

 it "continues to receive messages following consumer_cancel_notify message" do
   ::ActionSubscriber::start_subscribers!
   ::ActivePublisher.publish("zombie.groan", "uuunngg", "events")
   
   delete_queue!
   sleep 5.0

   ::ActivePublisher.publish("zombie.groan", "meeuuhhh", "events")
   verify_expectation_within(5.0) do
     expect($messages).to eq(Set.new(["uuunngg", "meeuuhhh"]))
   end
 end

 def delete_queue!
  http_client.delete_queue("/","alice.zombie.groan")
 end
end
