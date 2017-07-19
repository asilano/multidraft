source 'https://rubygems.org'

ruby '~> 2.3.0'
gem 'rails', '~> 4.0.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg', '~> 0.21.0'

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'sassy-buttons'
  gem 'coffee-rails'
  gem 'modernizr-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier'
#end

group :development, :test do
  gem "rspec-rails"
  gem "factory_girl_rails"

  # Use thin web-server in dev
  gem 'thin'
end

group :development do
  gem "quiet_assets"
  gem "better_errors", '~> 1.0'
  gem "binding_of_caller"
  gem "erb2haml"
end

group :test do
  # Turn off debugger for compatability
  # gem 'debugger'
  gem "database_cleaner"
  gem "email_spec"
  gem "launchy"
  gem "capybara"
  gem 'selenium-webdriver'
  gem 'coveralls', require: false
  gem 'codeclimate-test-reporter', require: false
  gem 'timecop'
  gem 'shoulda-matchers'

  # Let Travis see Rake
  gem 'rake'
end

group :production do
  gem 'rails_12factor'

  # Use unicorn as the web server
  gem 'unicorn'
end

gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'attribute_normalizer'
gem 'andand'

# github.com/laserlemon/figaro - provide config in .gitignored application.yml
# accessible through ENV (like Heroku does)
gem 'figaro'

# User authentication by devise and OpenID via OmniAuth
gem 'devise'
gem 'omniauth-openid'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

# Squeel - simpler SQL queries through AREL
gem 'squeel'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
