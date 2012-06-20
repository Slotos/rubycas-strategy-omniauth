require "rubycas-strategy-facebook/version"
require "sequel"
require "omniauth-facebook"
require "addressable/uri"

module CASServer
  module Strategy
    module Facebook
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

        def link(path)
          %[<a href="#{path}"><img alt="Log in with Facebook" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAMAAAAM7l6QAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAV9QTFRFVHCncIi2cYm2bYW0XXisPFyZ4ebvMlOUOFiXKkyQLlCSna3MMVKULE+Rnq7NyNHjQF+cusXbOVmYPV2aNleW8PL3OFmXM1SVVnKotMDYeI65b4e1rbvUL1GTlafJjqHEwszfNVWWJkmO6+/0U2+mnKzLbISy5urxZ4CxzNTlzdXmPFyal6jJT2ykVXGnX3qtuMTaPl2aOluZIESLx9Diu8bbTGmjt8PaKEuPSGagKUuQwcvfvsndKUyPOlqYXnisW3aqPVyZNleXNlaW6u30/f3+RWOeYHutXHar2d/s3eLt193qMVOUY32vUm6ldIu3coq3tsHZ3OLsc4m1dYy5YHqtG0CIOFiYw83gVnGoMFKTucTbnKzMwszgboa1c4u4oK/Oz9fmxs/ir7zWdo25ZoCxTGmidIy4X3itTWqihJi/HEGIp7bRb4a0N1iXa4OzeY+6N1eXQWCc////O1uZx/K/HgAAABB0Uk5T////////////////////AOAjXRkAAAEvSURBVHjarNNXb8IwFIZhQ5uELGhTICmjQIHuvTfde++9907C/1e/gFSrwslV36sjPbJ0LMskZHkUIkXPiOWlFov7AgLSXdic2ePRgM7i9vVFfsFGzQKL51527VI8k0fey2pHFBaP5UFrTbHYR5TBgakd8HV/MqlwLO4dBMsS896c2qjWgxveRFGtPG2m8sFV8E2HLKfMClYi9m+MzQWeMuPeSpZytvJ0JjF+PO+cnEinExn3zQ+Zm+PedbXgoOTy3v/N0bBJ07Ue8PkkxrAGruE2D6pp09234LscxqWhI4cLVz7a5XYb+OwB49OJ6fCyr4r2FW8FD29g9JMSP+/7afGtFfBFC8Z7A2xxjwah5bpeZVn+7sRojGoWPtGfzc1ZSRTF08/y5kXi/QV/BBgA/go2OS2QHDcAAAAASUVORK5CYII=" /></a> ]
        end
      end

      def self.registered(app)
        # Faraday won't work with facebook ssl certificate on some machines when using net/http. Using another adapter.
        Faraday.default_adapter = :typhoeus

        settings = app.workhorse

        app.set :facebook_matcher, Worker.new(settings)

        # Register omniauth interface
        key = settings["consumerkey"]
        secret = settings["consumersecret"]
        app.use ::OmniAuth::Builder do
          provider :facebook, key, secret
        end

        app.get "#{app.uri_path}/auth/facebook/callback" do
          auth = request.env['omniauth.auth']

          if match = app.settings.facebook_matcher.match(auth["uid"])
            confirm_authentication!( match[:email], session["service"] )
          else
            if ( target = Addressable::URI.parse settings["redirect_new"] ).host
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

          # Redirect to login page if we're still here. Preserve service and renew data
          redirector = Addressable::URI.new
          redirector.query_values = {
              :service => session[:service],
              :renew => session[:renew]
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

        app.add_oauth_link app.settings.facebook_matcher.link("#{app.uri_path}/auth/facebook")
      end
    end
  end
end
