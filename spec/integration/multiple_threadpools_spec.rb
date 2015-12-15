class DifferentThreadpoolsSubscriber < ActionSubscriber::Base
  def one
    $messages << payload
  end

  def two
    $messages << payload
  end
end

describe "Separate Threadpools for Different Message", :integration => true do
  let(:draw_routes) do
    low_priority_threadpool = ::ActionSubscriber::Threadpool.new_pool(:low_priority, 1)
    ::ActionSubscriber.draw_routes do
      route DifferentThreadpoolsSubscriber, :one
      route DifferentThreadpoolsSubscriber, :two, :threadpool => low_priority_threadpool
    end
  end

  it "processes messages in separate threadpools based on the routes" do
    ::ActionSubscriber.auto_subscribe!
    ::ActionSubscriber::Publisher.publish("different_threadpools.one", "ONE", "events")
    ::ActionSubscriber::Publisher.publish("different_threadpools.two", "TWO", "events")

    verify_expectation_within(2.0) do
      expect($messages).to eq(Set.new(["ONE","TWO"]))
    end
  end
end
