class UserSubscriber < ActionSubscriber::Base
  publisher :bob
  exchange :events

  # By turning on the at_most_once! mode we will tell rabbit
  # to expect message acknowledgements, but ActionSubscriber
  # will handle sending those acknowledgements right before
  # it calls your subscriber. This way you don't have to worry
  # about the same message being sent to you twice.
  at_most_once!

  def created
    UserProfile.create_for_user(payload)
  end
end
