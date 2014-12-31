ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'simplecov'
SimpleCov.start

require 'rails/test_help'
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
require 'factory_girl'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Rails.logger.level = 4

RSpec.configure do |config|
  # Avoid having to write FactoryGirl.create
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    # Test all factories validity
    FactoryGirl.lint
  end
end
