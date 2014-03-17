require 'spec_helper'
require 'action_subscriber/middleware/active_record/connection_management'

describe ActionSubscriber::Middleware::ActiveRecord::ConnectionManagement do
  include_context 'middleware env'

  before { ActiveRecord::Base.better_stub(:clear_active_connections!) }

  subject { described_class.new(app) }

  it_behaves_like 'a middleware'

  it "clears active connections" do
    ActiveRecord::Base.better_receive(:clear_active_connections!)
    subject.call(env)
  end
end
