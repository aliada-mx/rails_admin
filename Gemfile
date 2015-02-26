source 'https://rubygems.org'
source 'https://rails-assets.org'

# BASE
#
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.9'
# Use sqlite3 as the database for Active Record
gem 'pg'
gem 'mysql2'
# Use SCSS for stylesheets
gem 'state_machine'
# Settings management
gem "settingslogic"
# Server
gem 'unicorn'
# Background jobs
gem 'resque'
gem 'resque-scheduler'
gem 'resque-web', require: 'resque_web'
# Support for add_foreing_key (we downgraded from 4.2 to 4.1)
gem 'foreigner'

# ASSETS
#
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# Easy file attachment management for ActiveRecord
gem 'paperclip'
# AWS storage adapter
gem 'aws-sdk', '~> 1.5.7'
# Bootstrap
gem 'bootstrap-sass'
# Sass framework
gem 'compass-rails'
 
# JAVASCRIPT 
#
gem 'rails-assets-underscore'
gem 'rails-assets-knockout'
# Named railes routes for js
gem "js-routes"


# TEMPLATING
#
gem "haml-rails"
# Better template nesting
gem 'nestive'

# Authentication
gem 'devise'

# Time pargin
gem 'chronic'

# PAYMENT SYSTEMS
gem 'conekta'

# Invert <=> operator for sortings
gem 'invert'

# ADMIN
gem 'rails_admin', github: 'grillermo/rails_admin'
# permissions
gem 'cancancan'

group :development, :test do
  # Call 'pry' anywhere in the code to stop execution and get a debugger console
  gem 'pry-rails'
  # Automatically call pry on exception
  gem 'pry-rescue'
  # Browse the stack on pry
  gem 'pry-stack_explorer'

  # Improve rails error displaying
  gem 'better_errors'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Silent the assets from the logs
  gem 'quiet_assets', '~> 1.0.3'

  # Guard to compile as file changes
  gem 'guard-sass', require: false
  gem 'guard-livereload', require: false

  # Convert erb to haml
  gem 'erb2haml'

end

group :test do
  # Testing framework
  gem 'rspec-rails', '~> 3.0.1'

  # Functional testing
  gem 'capybara'

  # Factories
  gem 'factory_girl_rails'

  # Testing coverage
  gem 'simplecov', :require => false

  # Clean database after each test
  gem 'database_cleaner'

  # Open the browser
  gem 'launchy'

  # Profiling
  gem 'ruby-prof'

  # Manipulate time in your tests
  gem 'timecop'

  # Mocking requests
  gem 'webmock'

  # Record requests to be replayed on tests
  gem 'vcr'
end

group :production do
  # Logging
  gem "lograge"
end
