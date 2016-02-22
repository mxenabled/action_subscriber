describe ::ActionSubscriber::Threadpool do
  describe "busy?" do
    context "when the pool is busy" do
      it "returns true" do
        allow(::ActionSubscriber::Threadpool).to receive(:ready?).and_return(false)
        expect(::ActionSubscriber::Threadpool).to be_busy
      end
    end

    context "when the pool is not busy" do
      it "returns false" do
        allow(::ActionSubscriber::Threadpool).to receive(:ready?).and_return(true)
        expect(::ActionSubscriber::Threadpool).to_not be_busy
      end
    end
  end

  describe "ready?" do
    context "when all the workers are full" do
      it "returns false" do
        ::ActionSubscriber::Threadpool.new_pool(:some_dumb_pool, 2)

        ::ActionSubscriber::Threadpool.pools.map do |_name, pool|
          allow(pool).to receive(:busy_size).and_return(pool.pool_size)
        end

        expect(::ActionSubscriber::Threadpool).to_not be_ready
      end
    end

    context "when only one of the workers is full" do
      it "returns true" do
        pool = ::ActionSubscriber::Threadpool.new_pool(:some_other_dumb_pool, 2)
        allow(pool).to receive(:busy_size).and_return(2)

        expect(::ActionSubscriber::Threadpool).to be_ready
      end
    end

    context "when there are idle workers" do
      it "returns true" do
        allow(::ActionSubscriber::Threadpool.pool).to receive(:busy_size).and_return(1)
        expect(::ActionSubscriber::Threadpool).to be_ready
      end
    end
  end
end
