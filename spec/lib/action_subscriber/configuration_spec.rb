describe ::ActionSubscriber::Configuration do
  describe "default values" do
    specify { expect(subject.allow_low_priority_methods).to eq(false) }
    specify { expect(subject.default_exchange).to eq("events") }
    specify { expect(subject.host).to eq("localhost") }
    specify { expect(subject.port).to eq(5672) }
    specify { expect(subject.threadpool_size).to eq(8) }
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
