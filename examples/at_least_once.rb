class UserSubscriber < ActionSubscriber::Base
  publisher :bob
  exchange :events

  # By turning on the at_least_once! mode we will tell rabbit
  # to expect message acknowledgements, but ActionSubscriber
  # will handle sending those acknowledgements right after
  # it calls your subscriber. If your subscriber raises an error
  # we will reject the message which causes rabbit to try it again.
  # This way if you have an intermittent error (like a failed databse connection)
  # you can get the message again later.
  at_least_once!

  def created
    UserProfile.create_for_user(payload)
  end
end
