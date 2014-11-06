class UserSubscriber < ActionSubscriber::Base

  # In this example, we are in an application called "alice"
  # We want to listen to events in bob when bob creates a user.
  # When bob creates a user, bob publishes to "bob.user.created",
  # on an exchange called events.
  #
  # This subscriber listens to bob's events and executes the created
  # method every time bob publishes to the created queue.

  publisher :bob
  exchange :events

  # Will create the queue:
  #   alice.bob.user.created
  # With the routing key:
  #   bob.user.created
  #
  def created
    send_email(payload)
  end

  private

  # This is a private method and will be invisible to ActionSubscriber
  #
  def send_email(user)
    # MyMailer.send_welcome_email(user.email, user.name)
  end
end
