require "thread"

module ActionSubscriber
  module Publisher
    module Async
      class InMemoryAdapter
        attr_reader :async_queue

        def initialize
          @async_queue = AsyncQueue.new
        end

        def publish(route, payload, exchange_name, options = {})
          message = Message.new(route, payload, exchange_name, options)
          async_queue.push(message)
          nil
        end
      end

      class Message
        attr_reader :route, :payload, :exchange_name, :options

        def initialize(route, payload, exchange_name, options)
          @route = route
          @payload = payload
          @exchange_name = exchange_name
          @options = options
        end
      end

      class UnableToPersistMessageError < ::StandardError
      end

      class AsyncQueue
        include ::ActionSubscriber::Logging

        attr_reader :consumer, :queue, :supervisor

        MAXIMUM_QUEUE_SIZE = 1_000_000.freeze

        if ::RUBY_PLATFORM == "java"
          NETWORK_ERRORS = [::MarchHare::Exception, ::Java::ComRabbitmqClient::AlreadyClosedException, ::Java::JavaIo::IOException].freeze
        else
          NETWORK_ERRORS = [::Bunny::Exception, ::Timeout::Error, ::IOError].freeze
        end

        def initialize
          @queue = ::Queue.new
          create_and_supervise_consumer!
        end

        def push(message)
          # TODO: How do we exert backpressure here? Do we block the thread, or do we raise an error?
          fail UnableToPersistMessageError, "Queue is full, messages will be dropped." if queue.size > MAXIMUM_QUEUE_SIZE

          queue.push(message)
        end

      private

        def create_and_supervise_consumer!
          @consumer = create_consumer
          @supervisor = ::Thread.new do
            loop do
              unless consumer.alive?
                # Why might need to requeue the last message.
                queue.push(@current_message) if @current_message.present?
                consumer.kill
                @consumer = create_consumer
              end

              # Pause before checking the consumer again.
              sleep supervisor_interval
            end
          end
        end

        def create_consumer
          ::Thread.new do
            loop do
              # Write "current_message" so we can requeue should something happen to the consumer. I don't love this, but it's
              # better than writing my own `#peek' method.
              @current_message = message = queue.pop

              begin
                ::ActionSubscriber::Publisher.publish(message.route, message.payload, message.exchange_name, message.options)

                # Reset
                @current_message = nil
              rescue *NETWORK_ERRORS
                # Sleep because the connection is down.
                sleep ::ActionSubscriber::RabbitConnection::NETWORK_RECOVERY_INTERVAL
                # Requeue and try again.
                queue.push(message)
              rescue => unknown_error
                # Do not requeue the message because something else horrible happened.
                @current_message = nil

                # Log the error.
                logger.info unknown_error.class
                logger.info unknown_error.message
                logger.info unknown_error.backtrace.join("\n")

                # TODO: Find a way to bubble this out of the thread for logging purposes.
                # Reraise the error out of the publisher loop. The Supervisor will restart the consumer.
                raise unknown_error
              end
            end
          end
        end

        def supervisor_interval
          @supervisor_interval ||= begin
            interval_in_milliseconds = ::ActionSubscriber.configuration.async_message_supervisor_interval
            interval_in_milliseconds / 1000.0
          end
        end
      end
    end
  end
end