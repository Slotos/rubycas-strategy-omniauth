# CASServer::Strategy::OmniAuth

Provides mechanism to authenticate users with Omniauth strategies optionally matching them against your central SQL user database. The latter part was developed with devise in mind.

## Installation

Ensure this gem is reachable by rubycase server, which depends on how you run it.

If you run rubycase-server as sinatra, be it alone or mounted to another app - add this line to Gemfile:

    gem 'rubycas-strategy-omniauth', :git => 'git://github.com/Slotos/rubycas-strategy-omniauth.git'

Also remember to add whatever omniauth strategies you will employ. I.e. if you're going to use twitter and google omniauth strategies:

    gem 'omniauth-twitter'
    gem 'omniauth-google'

And then execute:

    bundle

If you run is as centralized system service - install gem by running:

    gem install rubycas-strategy-omniauth

Of course I lied, there's no way to install it that way unless I release it as a gem =P

## Usage

For now you'll have to use my fork of rubycas-server if you want to use this strategy. Example configuration lines for config.yml follow (database line is Sequel compatible):

````yaml
strategies:
  -
    strategy: OmniAuth
    omniauth: # it gets transformed into `OmniAuth::Builder { provider omniauth['provider'], *omniauth['args'] }`.
      strategy: omniauth-facebook # optional, for when omniauth strategy gem name cannot be derived from provider option
      provider: facebook
      args: ['key', 'secret']
    matcher:
      database:
        adapter: mysql2
        database: db
        username: user
        password: secret
      user_table: users
      username_column: email
      token_table: access_tokens
      foreign_key: user_id
      uid_column: uid
      provider_column: provider
      provider_name: twitter # optional, uses omniauth provider name if missing
      redirect_new: 'https://lvh.me/registration/' # Mind it, https protocol will be enforced, since sensitive data will be sent in GET request.
  -
    strategy: OmniAuth
    omniauth:
      provider: twitter
      args: ['key', 'secret']
    matcher:
      database:
        adapter: mysql2
        database: db
        username: user
        password: secret
      user_table: users
      username_column: email
      token_table: access_tokens
      foreign_key: user_id
      uid_column: uid
      provider_column: provider
      redirect_new: 'https://lvh.me/registration/'
````

If you don't want to match users against your local data - provide `passthrough: true` for matcher:

````yaml
strategies:
  -
    strategy: OmniAuth
    omniauth:
      strategy: omniauth-google-oauth2
      provider: google_oauth2
      args:
        - key
        - secret
        -
          scope: "userinfo.email,userinfo.profile,https://www.googleapis.com/auth/calendar"
    matcher:
      passthrough: true
````

CAS server will provide `info` and `provider` data in extra attributes. For reference on what constitutes `info` and `provider` head to [OmniAuth wiki](https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema)
