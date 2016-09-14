class MultipleConnectionsSubscriber < ::ActionSubscriber::Base
  MUTEX = ::Mutex.new
  at_least_once!

  def burp
    sleep 0.1
    MUTEX.synchronize do
      $messages << payload
    end
  end
end

describe "Separate connections to get multiple threadpools", :integration => true do
  let(:draw_routes) do
    ::ActionSubscriber.draw_routes do
      connection(:background_work, :thread_pool_size => 20) do
        route MultipleConnectionsSubscriber, :burp,
          :acknowledgements => true,
          :concurrency => 20
      end
      route MultipleConnectionsSubscriber, :burp,
          :acknowledgements => true,
          :concurrency => 8 # match the default threadpool size
    end
  end

  it "spreads the load across multiple threadpools and consumer" do
    ::ActionSubscriber.auto_subscribe!
    1.upto(2_800).each do |i|
      ::ActivePublisher.publish("multiple_connections.burp", "belch #{i}", "events")
    end

    verify_expectation_within(18.0) do
      expect($messages.size).to eq(2_800)
    end
  end
end
