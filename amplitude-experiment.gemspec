require File.expand_path('lib/experiment/version', __dir__)
Gem::Specification.new do |spec|
  spec.name                  = 'amplitude-experiment'
  spec.version               = AmplitudeExperiment::VERSION
  spec.authors               = ['Amplitude']
  spec.email                 = ['sdk@amplitude.com']
  spec.summary               = 'Amplitude Experiment Ruby Server SDK'
  spec.description           = 'Amplitude Experiment Ruby Server SDK'
  spec.homepage              = 'https://github.com/amplitude/experiment-ruby-server'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.0'

  spec.files                 = Dir['README.md',
                                   'lib/**/*.rb',
                                   'experiment-ruby.gemspec',
                                   'Gemfile',
                                   'lib/experiment/local/evaluation/lib/**/*.so',
                                   'lib/experiment/local/evaluation/lib/**/*.dylib']
  spec.require_paths         = ["lib"]
  spec.extra_rdoc_files      = ['README.md']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rdoc', '~> 6.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'webmock', '~> 3.14'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.metadata['rubygems_mfa_required'] = 'false'
  spec.add_runtime_dependency 'ffi', '~> 1.15.5'
end
