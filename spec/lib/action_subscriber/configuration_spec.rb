describe ::ActionSubscriber::Configuration do
  describe "default values" do
    specify { expect(subject.allow_low_priority_methods).to eq(false) }
    specify { expect(subject.async_publisher).to eq("memory") }
    specify { expect(subject.async_publisher_drop_messages_when_queue_full).to eq(false) }
    specify { expect(subject.async_publisher_max_queue_size).to eq(1_000_000) }
    specify { expect(subject.async_publisher_supervisor_interval).to eq(200) }
    specify { expect(subject.default_exchange).to eq("events") }
    specify { expect(subject.heartbeat).to eq(5) }
    specify { expect(subject.host).to eq("localhost") }
    specify { expect(subject.mode).to eq('subscribe') }
    specify { expect(subject.pop_interval).to eq(100) }
    specify { expect(subject.port).to eq(5672) }
    specify { expect(subject.prefetch).to eq(5) }
    specify { expect(subject.seconds_to_wait_for_graceful_shutdown).to eq(30) }
    specify { expect(subject.threadpool_size).to eq(8) }
    specify { expect(subject.timeout).to eq(1) }
    specify { expect(subject.times_to_pop).to eq(8) }
  end

  describe "add_decoder" do
    it "add the decoder to the registry" do
      subject.add_decoder({"application/protobuf" => lambda { |payload| "foo"} })
      expect(subject.decoder).to include("application/protobuf")
    end

    it 'raises an error when decoder does not have arity of 1' do
      expect {
        subject.add_decoder("foo" => lambda { |*args|  })
      }.to raise_error(/The foo decoder was given with arity of -1/)

      expect {
        subject.add_decoder("foo" => lambda {  })
      }.to raise_error(/The foo decoder was given with arity of 0/)

      expect {
        subject.add_decoder("foo" => lambda { |a,b| })
      }.to raise_error(/The foo decoder was given with arity of 2/)
    end
  end
end
