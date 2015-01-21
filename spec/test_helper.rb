ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'simplecov'
SimpleCov.start

require 'rails/test_help'
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
require 'factory_girl'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Rails.logger.level = 4

RSpec.configure do |config|
  DatabaseCleaner.strategy = :truncation

  # Avoid having to write FactoryGirl.create
  config.include FactoryGirl::Syntax::Methods
  # Route helpers
  config.include Rails.application.routes.url_helpers
  # Test driver helpers
  config.include TestingSupport::DriverHelpers

  config.before(:suite) do

    # Test all factories validity
    FactoryGirl.lint

    # Clean database
    DatabaseCleaner.clean_with(:truncation)

    # Use faster transaction strategy
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    # Track transactions
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
