# -*- encoding : utf-8 -*-
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
require 'webmock/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb

  config.register_request_matcher :conekta_charge do |real_request, recorded_request|
    charge_regex = /^https:\/\/.*:@api.conekta.io\/charges\?amount=\d+&card=.*&currency=MXN&description=.*&reference_id=\d+/

    real_request.uri == recorded_request.uri || (charge_regex.match(real_request.uri) && charge_regex.match(recorded_request.uri))
  end
end


RSpec.configure do |config|

  # Authentication helpers
  config.include TestingSupport::DeviseHelpers

  # Avoid having to write FactoryGirl.create
  config.include FactoryGirl::Syntax::Methods

  # Syntax candy over capybara uglyness
  config.include TestingSupport::CapybaraHelpers

  # Route helpers
  config.include Rails.application.routes.url_helpers

  # Test driver helpers
  config.include TestingSupport::DriverHelpers

  config.before(:suite) do
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

  config.after(:suite) do
    DatabaseCleaner.clean
  end

end
