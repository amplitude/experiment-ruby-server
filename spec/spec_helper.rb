require 'webmock/rspec'
require 'experiment'
require 'simplecov'

WebMock.disable_net_connect!(allow_localhost: true)

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end
