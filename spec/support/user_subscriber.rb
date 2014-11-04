class UserSubscriber < ActionSubscriber::Base
  exchange :events

  def created
  end
end
