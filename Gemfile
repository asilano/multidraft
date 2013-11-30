source 'https://rubygems.org'

ruby '1.9.3'
gem 'rails', '~> 3.2.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem "rspec-rails"
  gem "factory_girl_rails"
  gem "spork-rails"
end

group :development do
  gem "quiet_assets"
  gem "better_errors"
  gem "binding_of_caller"
  gem "erb2haml"
end

group :test do
  gem "database_cleaner"
  gem "email_spec"
  gem "launchy"
  gem "capybara"
end

gem 'jquery-rails'
gem 'haml'
gem 'haml-rails'

# github.com/laserlemon/figaro - provide config in .gitignored application.yml
# accessible through ENV (like Heroku does)
gem 'figaro'

# User authentication by devise and OpenID
gem 'devise'
gem 'devise_openid_authenticatable'


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
