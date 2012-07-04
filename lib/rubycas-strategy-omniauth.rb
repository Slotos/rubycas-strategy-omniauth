require "rubycas-strategy-omniauth/version"
require "sequel"
require "addressable/uri"

module CASServer
  module Strategy
    module Omniauth
      class Worker
        def initialize(config)
          raise "Expecting config" unless config.is_a?(::Hash)
          @token_table = config['token_table']

          @connection = Sequel.connect(config['database'])
          @dataset = @connection.from(config['token_table']).join(config['user_table'].to_sym, :id => config['foreign_key_column'].to_sym).where(config['provider_column'].to_sym => 'facebook')
        end

        def match(uid)
          matcher = @dataset.where("#{@token_table}__uid".to_sym => uid)
          raise "Multiple matches, database tainted" if matcher.count > 1
          matcher.first
        end
      end

      def self.registered(app)
        settings = app.workhorse

        require settings['omniauth-strategy'] || "omniauth-#{settings['provider']}"

        # Faraday won't work with facebook ssl certificate on some machines when using net/http. Using another adapter.
        Faraday.default_adapter = :typhoeus

        worker_name = :"#{settings['provider']}_worker"
        app.set worker_name, Worker.new(settings)

        # Register omniauth interface
        key = settings["consumerkey"]
        secret = settings["consumersecret"]
        app.use ::OmniAuth::Builder do
          provider :facebook, key, secret
        end

        app.get "#{app.uri_path}/auth/facebook/callback" do
          auth = request.env['omniauth.auth']

          if match = app.settings.facebook_worker.match(auth["uid"])
            establish_session!( match[:email], session["service"] )
          else
            if ( target = Addressable::URI.parse settings["redirect_new"].to_s ).host
              target.scheme = "https"
              target.query_values = {}.merge(
                "provider" => auth["provider"],
                "uid" => auth["uid"],
                "info" => auth["info"],
                "credentials" => auth["credentials"]
              )
              redirect to( target.to_s )
            end
          end

          # Redirect to login page if we're still here. Preserve service data
          redirector = Addressable::URI.new
          redirector.query_values = {
              :service => session[:service],
          }.delete_if{|_,v| v.nil? || v.empty?}
          redirector.path = "#{app.uri_path}/login"
          redirect to(redirector.to_s), 303
        end

        app.get "#{app.uri_path}/auth/failure", :when_params => {"strategy" => "facebook"} do
          redirector = Addressable::URI.new
          redirector.query_values = {
            :service => session[:service],
            :renew => session[:renew],
            :oauth_error => params[:message],
            :oauth_strategy => params[:strategy]
          }.delete_if{|_,v| v.nil? || v.empty?}
          redirector.path = "#{app.uri_path}/login"
          redirect to(redirector.to_s), 303
        end

        app.add_oauth_link app.settings.facebook_worker.link("#{app.uri_path}/auth/facebook")
      end
    end
  end
end
