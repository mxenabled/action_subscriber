class UserSubscriber < ActionSubscriber::Base
  exchange :events

  def created(payload)
  end
end
