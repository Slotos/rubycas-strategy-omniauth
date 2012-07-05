class CASServer::Mock < Sinatra::Base
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
    "/test"
  end

  def self.add_login_link(link)
    @login_link = link
  end

  configure do
    set :workhorse, $config["strategies"]
    require File.expand_path(File.dirname(File.dirname(__FILE__)) + '/lib/rubycas-strategy-omniauth')
    register CASServer::Strategy::OmniAuth
  end
end
