require "rubycas-strategy-omniauth/version"
require "sequel"
require "addressable/uri"

module CASServer
  module Strategy
    module OmniAuth
      class Worker
        def initialize(config)
          raise "Expecting config" unless config.is_a?(::Hash)
          @config = config
          return if @config['passthrough']

          @connection = Sequel.connect(@config['database'])
          @dataset = @connection.
            from( @config['token_table'] ).
            join( :"#{@config['user_table']}", :id => :"#{@config['foreign_key']}" ).
            where( :"#{@config['provider_column']}" => @config['provider_name'])
        end

        def match(uid)
          return uid if @config['passthrough']
          matcher = @dataset.where(:"#{@config['token_table']}__#{@config['uid_column']}" => uid)
          raise "Multiple matches, database tainted" if matcher.count > 1
          matcher.first[:"#{@config['username_column']}"] if matcher.first
        end

        def link(url, text = nil)
          %(<a href="#{url}">#{text}</a>)
        end
      end

      def self.registered(app)
        settings = app.workhorse
        omniauth = settings['omniauth']
        matcher = settings['matcher']

        require omniauth['strategy'] || "omniauth-#{omniauth['provider']}"

        # Faraday won't work with facebook ssl certificate on some machines when using net/http. Using another adapter.
        Faraday.default_adapter = :typhoeus if Kernel.const_defined?("Faraday")

        worker_name = :"#{omniauth['provider']}_worker"
        worker_settings = :"#{omniauth['provider']}_settings"
        matcher['provider_name'] ||= omniauth['provider'] # this will rarely differ
        app.set worker_name, Worker.new(matcher)
        app.set worker_settings, matcher

        # Register omniauth interface
        app.use ::OmniAuth::Builder do
          provider omniauth['provider'], *omniauth['args']
        end

        auth_name = ::OmniAuth::Strategies.const_get( ::OmniAuth::Utils.camelize(omniauth['provider']) ).default_options['name'] || omniauth['provider']

        # Omniauth callback
        app.get "#{app.uri_path}/auth/#{auth_name}/callback" do
          auth = request.env['omniauth.auth']

          # Only the basic information that would allow service to address the user. No keys or anything, since any service can access CAS server.
          # In case of facebook or twitter login without remote-to-local match username will be numeric unique identifier. That's the reason for this.
          extra_attributes = {
            "provider" => auth["provider"],
            "info" => auth["info"]
          }

          if name = app.settings.send(worker_name).match(auth["uid"])
            establish_session!( name, session["service"], extra_attributes )
          else
            if ( target = Addressable::URI.parse matcher["redirect_new"].to_s ).host
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

        # Omniauth failure, limited to our specific strategy.
        app.get "#{app.uri_path}/auth/failure", :when_params => {"strategy" => auth_name} do
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

        app.add_login_link app.settings.send(worker_name).link("#{app.uri_path}/auth/#{auth_name}", settings['link_text'] || "Login with #{omniauth['provider'].capitalize}")
      end
    end
  end
end
