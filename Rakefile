default_tasks = []

task default: :spec
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

default_tasks << :spec

if RUBY_VERSION >= '2.1'
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
  end

  default_tasks << :rubocop
end

task default: default_tasks

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Amplitude Experiment Ruby SDK'
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', '-', 'README.md']
end
