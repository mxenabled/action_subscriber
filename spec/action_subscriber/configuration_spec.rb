require 'spec_helper'

describe ::ActionSubscriber::Configuration do
  describe "default values" do
    its(:allow_low_priority_methods) { should be_false }
    its(:default_exchange) { should eq(:events) }
    its(:host) { should eq('localhost') }
    its(:port) { should eq(5672) }
    its(:threadpool_size) { should eq(8) }
  end

  describe "add_decoder" do
    it "add the decoder to the registry" do
      subject.add_decoder({"application/protobuf" => lambda { |payload| "foo"} })
      subject.decoder.should include("application/protobuf")
    end
  end
end
