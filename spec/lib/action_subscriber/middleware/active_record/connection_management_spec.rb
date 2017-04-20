require 'action_subscriber/middleware/active_record/connection_management'

describe ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement do
  include_context 'action subscriber middleware env'

  before {
    pool = double("pool")
    allow(pool).to receive(:with_connection).and_yield
    allow(ActiveRecord::Base).to receive(:clear_active_connections!)
    allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool)
  }

  subject { described_class.new(app) }

  it_behaves_like 'an action subscriber middleware'

  it "starts async task to clear connections" do
    expect(ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement).to receive(:start_timed_task!)
    subject.call(env)
  end
end
