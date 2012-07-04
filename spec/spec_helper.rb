require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def config
  @config ||= YAML.load_file( File.expand_path(File.dirname(__FILE__) + '/example_config.yml') )
end

def init_db!
  @database = config["strategies"]["database"]
  db = Sequel.connect(@database)
  db.create_table :users do
    primary_key :id
    String :email, :unique => true
  end
  db.create_table :access_tokens do
    primary_key :id
    Fixnum :uid
    String :provider
    Fixnum :user_id
  end
  db.disconnect
end

def add_user(email, *args)
  options = args.last.is_a?(Hash) ? args.pop : {}
  db = Sequel.connect(@database)

  user_id = db[:users].insert(:email => email)
  options.delete_if{|k,_| !k.respond_to?(:to_s) }

  options.each do |provider, uid|
    db[:access_tokens].insert(:user_id => user_id, :uid => uid, :provider => provider.to_s)
  end

  db.disconnect
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.after :all do
    FileUtils.rm_f(config["strategies"]["database"]["database"])
  end
  conf.before :all do
    init_db!
  end
end

# START borrowed
# You can read about this gist at: http://wealsodocookies.com/posts/how-to-test-facebook-login-using-devise-omniauth-rspec-and-capybara

def set_omniauth(opts = {})
  default = {:provider => :facebook,
             :uuid     => "1234",
             :facebook => {
    :email => "foobar@example.com",
    :gender => "Male",
    :first_name => "foo",
    :last_name => "bar"
  }
  }

  credentials = default.merge(opts)
  provider = credentials[:provider]
  user_hash = credentials[provider]

  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[provider] = {
    'provider' => credentials[:provider],
    'uid' => credentials[:uuid],
    "extra" => {
    "user_hash" => {
    "email" => user_hash[:email],
    "first_name" => user_hash[:first_name],
    "last_name" => user_hash[:last_name],
    "gender" => user_hash[:gender]
  }
  }
  }
end

def set_invalid_omniauth(opts = {})

  credentials = { :provider => :facebook,
                  :invalid  => :invalid_crendentials
  }.merge(opts)

  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[credentials[:provider]] = credentials[:invalid]

end

# END borrowed

class CASServer::Mock < Sinatra::Base
  enable :sessions
  set :config, config

  # the easiest way to check if these are preserved on redirects
  enable :sessions

  def self.when_params(*args)
    desired_params = Hash[args]

    condition {
      desired_params.delete_if do |k,v|
      params[k.to_s] == v
      end
    desired_params.empty?
    }
  end

  def self.with_params(*args)
    args = [args] unless args.kind_of?(::Array)
    condition {
      (args.map(&:to_s) - params.keys.map(&:to_s)).empty?
    }
  end


  def self.uri_path
    ""
  end

  def self.add_oauth_link(link)
    @oauth_link = link
  end

  set :workhorse, config["strategies"]
  require File.expand_path(File.dirname(File.dirname(__FILE__)) + '/lib/rubycas-strategy-omniauth')
  register CASServer::Strategy::Omniauth
end

def app
  CASServer::Mock
end
