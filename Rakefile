require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

# Appraisal wires up per-Rails-version tasks (rake appraisal:rails-8.1 spec, etc.)
# when the appraisal gem is available. It is only a development dependency, so we
# guard the require to keep the Rakefile usable without it (e.g. from an installed gem).
begin
  require "appraisal"
rescue LoadError
  # appraisal not installed; per-version tasks are unavailable
end

desc "Run specs (default)"
task :default => :spec
