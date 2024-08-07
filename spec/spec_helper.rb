require 'simplecov'
require 'amplitude'
require 'amplitude-experiment'
require 'webmock/rspec'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end
WebMock.allow_net_connect!
