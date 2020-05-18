require "spec_helper"

describe ::ActionSubscriber::RabbitConnection do
  let(:reason) { "low on disk" }

  before { ActionSubscriber.draw_routes {} }

  if ::RUBY_PLATFORM == "java"
    it "can deliver an on_blocked message" do

    end
  else
    it "can deliver an on_blocked message" do
      expect(::ActiveSupport::Notifications).to receive(:instrument).
        with("connection_blocked.action_subscriber", :reason => reason)

      described_class.with_connection do |connection|
        # NOTE: Trigger the receiving of a blocked message from the broker.
        # It's a bit of a hack but it is a more realistic test without changing
        # memory alarms.
        connection.send(:handle_frame, 0, ::AMQ::Protocol::Connection::Blocked.new(reason))
      end
    end
  end
end
