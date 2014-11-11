class UserSubscriber < ActionSubscriber::Base
  publisher :users_hq
  exchange :events


  # When we turn on manual acknowledgements RabbitMQ will be expecting us
  # to send back either and acknowledgement or a rejection for each message
  # if we don't send anything back rabbit might stop sending us messages
  manual_acknowledgement!

  def created
    user_profile = UserProfile.create_for_user(payload)
    if user_profile.save
      acknowledge
    else
      reject
    end
  end
end
