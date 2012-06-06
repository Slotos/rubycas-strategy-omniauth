# CASServer::Matchers::Facebook

Provides mechanism to authenticate user with Facebook and then match them against your central SQL user database

## Installation

Ensure this gem is reachable by rubycase server, which depends on how you run it.

If you run rubycase-server as sinatra, be it alone or mounted to another app - add this line to Gemfile:

    gem 'rubycas-facebook-matcher', :git => git://github.com/Slotos/rubycas-facebook-matcher.git

And then execute:

    bundle

If you run is as centralized system service - install gem by running:

    gem install rubycas-facebook-matcher

Of course I lied, there's no way to install it that way unless I release it as a gem =P

## Usage

For now you'll have to use `generic_matchers` branch from my fork of rubycas-server if you want to use this matcher. All you need to do is add this definition to your config.yml (database line is Sequel compatible):

````yaml
matcher:
  facebook:
    database:
      adapter: mysql2
      database: db
      username: user
      password: secret
    user_table: users
    username_column: email
    token_table: access_tokens
    foreign_key_column: user_id
    provider_column: provider
    consumerkey: ''    # facebook App ID
    consumersecret: '' # facebook App secret
````

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
