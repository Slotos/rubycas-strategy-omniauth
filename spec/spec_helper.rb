require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'
#require 'capybara'
#require 'capybara/dsl'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

#Capybara.app = CASServer::Server

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

class CASServer::Mock < Sinatra::Base
  require File.expand_path(File.dirname(File.dirname(__FILE__)) + '/lib/rubycas-facebook-matcher')
end

def app
  CASServer::Mock
end
