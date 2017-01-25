describe ::ActionSubscriber::Configuration do
  describe "default values" do
    specify { expect(subject.allow_low_priority_methods).to eq(false) }
    specify { expect(subject.default_exchange).to eq("events") }
    specify { expect(subject.heartbeat).to eq(5) }
    specify { expect(subject.host).to eq("localhost") }
    specify { expect(subject.port).to eq(5672) }
    specify { expect(subject.prefetch).to eq(2) }
    specify { expect(subject.seconds_to_wait_for_graceful_shutdown).to eq(30) }
    specify { expect(subject.threadpool_size).to eq(8) }
    specify { expect(subject.timeout).to eq(1) }
    specify { expect(subject.tls).to eq(false) }
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

  describe "connection_string" do
    it "explodes the connection string into the corresponding settings" do
      subject.connection_string = "amqp://user:pass@host:100/vhost"
      expect(subject.username).to eq("user")
      expect(subject.password).to eq("pass")
      expect(subject.host).to eq("host")
      expect(subject.port).to eq(100)
      expect(subject.virtual_host).to eq("vhost")
    end
  end
end
