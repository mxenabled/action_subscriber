require "spec_helper"

describe ::ActionSubscriber::RabbitConnection do
  let(:reason) { "low on disk" }

  before { ActionSubscriber.draw_routes {} }

  context "on_block" do
    if ::RUBY_PLATFORM == "java"
      def trigger_mocked_blocking_event(connection, reason)
        amqp_message = ::Java::ComRabbitmqClient::AMQP::Connection::Blocked::Builder.new.
          reason(reason).build
        amq_command = ::Java::ComRabbitmqClientImpl::AMQCommand.new(amqp_message)

        connection.send(:processControlCommand, amq_command)
      end
    else
      def trigger_mocked_blocking_event(connection, reason)
        connection.send(:handle_frame, 0, ::AMQ::Protocol::Connection::Blocked.new(reason))
      end
    end

    it "can deliver an on_blocked message" do
      expect(::ActiveSupport::Notifications).to receive(:instrument).
        with("connection_blocked.action_subscriber", :reason => reason)

      described_class.with_connection do |connection|
        # NOTE: Trigger the receiving of a blocked message from the broker.
        # It's a bit of a hack but it is a more realistic test without changing
        # memory alarms.
        trigger_mocked_blocking_event(connection, reason)
      end
    end
  end

  context "on_unblocked" do
    if ::RUBY_PLATFORM == "java"
      def trigger_mocked_unblocked_event(connection, reason)
        amqp_message = ::Java::ComRabbitmqClient::AMQP::Connection::Unblocked::Builder.new.
          build
        amq_command = ::Java::ComRabbitmqClientImpl::AMQCommand.new(amqp_message)

        connection.send(:processControlCommand, amq_command)
      end
    else
      def trigger_mocked_unblocked_event(connection, reason)
        connection.send(:handle_frame, 0, ::AMQ::Protocol::Connection::Unblocked.new)
      end
    end

    it "can deliver an on_unblocked message" do
      expect(::ActiveSupport::Notifications).to receive(:instrument).
        with("connection_unblocked.action_subscriber")

      described_class.with_connection do |connection|
        # NOTE: Trigger the receiving of an unblocked message from the broker.
        # It's a bit of a hack but it is a more realistic test without changing
        # memory alarms.
        trigger_mocked_unblocked_event(connection, reason)
      end
    end
  end
end
