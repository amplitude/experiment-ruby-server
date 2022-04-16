
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
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Amplitude Experiment Ruby SDK"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
