# Appraisal matrix for the Rails/ActiveSupport versions action_subscriber supports.
#
# Notes on Ruby compatibility when running this matrix in CI:
#   * rails 6.1 / 7.0 / 7.1 run on Ruby >= 2.7 (and on Ruby 3.4 with the
#     default-gem shims added below, since logger/mutex_m/bigdecimal/drb/base64
#     were removed from the default gem set).
#   * rails 7.2 requires Ruby >= 3.1.
#   * rails 8.0 / 8.1 require Ruby >= 3.2.
# Pair each gemfile with a compatible Ruby in the CI matrix.

# Shims required by ActiveSupport < 7.1 on Ruby >= 3.4 (default gems removed).
older_rails_shims = proc do
  gem "logger"
  gem "mutex_m"
  gem "bigdecimal"
  gem "drb"
  gem "base64"
  gem "benchmark"
end

appraise "rails-6.1" do
  instance_exec(&older_rails_shims)
  gem "activesupport", "~> 6.1.0"
  gem "activerecord", "~> 6.1.0"
end

appraise "rails-7.0" do
  instance_exec(&older_rails_shims)
  gem "activesupport", "~> 7.0.0"
  gem "activerecord", "~> 7.0.0"
end

appraise "rails-7.1" do
  gem "activesupport", "~> 7.1.0"
  gem "activerecord", "~> 7.1.0"
end

appraise "rails-7.2" do
  gem "activesupport", "~> 7.2.0"
  gem "activerecord", "~> 7.2.0"
end

appraise "rails-8.0" do
  gem "activesupport", "~> 8.0.0"
  gem "activerecord", "~> 8.0.0"
end

appraise "rails-8.1" do
  gem "activesupport", "~> 8.1.0"
  gem "activerecord", "~> 8.1.0"
end
