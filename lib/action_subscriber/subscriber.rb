module ActionSubscriber
  module Subscriber
    # resubscribes to queue, continuously retrying to subscribe in the event of a potentially recoverable error while
    # also calling the error handler to surface that a subscription failure happened
    def safely_restart_subscriber(subscription)
      subscription[:queue] = setup_queue(subscription[:route])
      start_subscriber_for_subscription(subscription)
    rescue StandardError => e
      ::ActionSubscriber.configuration.error_handler.call(e)
      raise e unless e.message =~ /queue .* process is stopped by supervisor/

      nap_time = rand(2.0..5.0)
      ::ActionSubscriber.logger.error("Failed to resubscribe to #{subscription[:queue].name}, retrying again in #{nap_time} seconds...")
      sleep(nap_time)
      retry
    end
  end
end
