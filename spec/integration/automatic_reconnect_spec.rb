require "rabbitmq/http/client"

class GusSubscriber < ActionSubscriber::Base
  def spoke
    $messages << payload
  end
end

describe "Automatically reconnect on connection failure", :integration => true, :slow => true do
  let(:connection) { subscriber.connection }
  let(:http_client) { RabbitMQ::HTTP::Client.new("http://127.0.0.1:15672") }
  let(:subscriber) { GusSubscriber }

  it "reconnects when a connection drops" do
    ::ActionSubscriber::auto_subscribe!
    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("First", :routing_key => "gus.spoke")
    verify_expectation_within(5.0) do
      expect($messages).to eq(Set.new(["First"]))
    end

    close_all_connections!
    sleep 5.0
    verify_expectation_within(5.0) do
      expect(connection).to be_open
    end

    channel = connection.create_channel
    exchange = channel.topic("events")
    exchange.publish("Second", :routing_key => "gus.spoke")
    verify_expectation_within(5.0) do
      expect($messages).to eq(Set.new(["First", "Second"]))
    end
  end

  def close_all_connections!
    http_client.list_connections.each do |conn_info|
      http_client.close_connection(conn_info.name)
    end
  end
end
