class MultipleConnectionsSubscriber < ::ActionSubscriber::Base
  MUTEX = ::Mutex.new
  at_least_once!

  def burp
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
    ::ActionSubscriber.start_subscribers!
    1.upto(10).each do |i|
      ::ActivePublisher.publish("multiple_connections.burp", "belch#{i}", "events")
    end

    verify_expectation_within(5.0) do
      expect($messages).to eq(Set.new(["belch1", "belch2", "belch3", "belch4", "belch5", "belch6", "belch7", "belch8", "belch9", "belch10"]))
    end
  end
end
