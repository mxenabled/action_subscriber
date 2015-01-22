describe ActionSubscriber::Middleware::Decoder do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  let(:env) { ActionSubscriber::Middleware::Env.new(UserSubscriber, encoded_payload, message_properties) }
  let(:encoded_payload) { JSON.generate(payload) }
  let(:payload) { {"ohai" => "GUYZ"} }

  context "when the content type has an associated decoder" do
    before { message_properties[:content_type] = "application/json"}

    it "decodes the payload" do
      subject.call(env)
      expect(env.payload).to eq(payload)
    end
  end

  context "when the content type does not have an associated decoder" do
    before { message_properties[:content_type] = "application/foo"}

    it "uses the payload as-is" do
      subject.call(env)
      expect(env.payload).to eq(encoded_payload)
    end
  end
end
