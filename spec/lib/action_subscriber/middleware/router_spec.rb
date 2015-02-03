describe ActionSubscriber::Middleware::Router do
  include_context 'action subscriber middleware env'

  subject { described_class.new(app) }

  it "routes the event to the proper action" do
    allow_any_instance_of(env.subscriber).to receive(env.action)
    subject.call(env)
  end
end
