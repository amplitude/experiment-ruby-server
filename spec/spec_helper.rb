require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

require 'amplitude-experiment'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
