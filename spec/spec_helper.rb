require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

unless ENV['DRB']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start('rails')
end

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'rspec/autorun'
  require 'timecop'
  require 'ruby-debug'

  Timecop.safe_mode = true
  Capybara.asset_host = "http://localhost:3000"

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/factories"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"

    config.include Capybara::DSL
    config.include(MailerMacros)
    config.include Warden::Test::Helpers

    config.expect_with(:rspec) { |c| c.syntax = :expect }

    config.before(:suite) do
      DatabaseCleaner.clean_with :truncation
    end

    config.before(:each) do
      if example.metadata[:js]
        DatabaseCleaner.strategy = :truncation
      else
        DatabaseCleaner.strategy = :transaction
      end
      DatabaseCleaner.start

      ActionMailer::Base.deliveries.clear
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

def login(user, opts = {})
  visit new_user_session_path
  fill_in "Username", with: user.name
  fill_in "Password", with: user.password
  click_button "Sign in"
  if opts[:fail]
    expect(page).to have_content 'Invalid username or password'
  else
    expect(page).to have_content "Signed in as #{user.name}"
  end
end