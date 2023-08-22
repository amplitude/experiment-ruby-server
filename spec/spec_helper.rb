require 'simplecov'
require 'amplitude'
require 'amplitude-experiment'
require 'webmock/rspec'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

WebMock.disable_net_connect!(allow_localhost: true)
