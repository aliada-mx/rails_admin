source 'https://rubygems.org'


# BASE
#
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'state_machine'
# Settings management
gem "settingslogic"

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
# Bootstrap
gem 'bootstrap-sass'
# Sass framework
gem 'compass-rails'

# TEMPLATING
#
gem "haml-rails"
# Better template nesting
gem 'nestive'

# AUTHENTICATION
gem 'devise'
gem 'simple_token_authentication', '~> 1.0'

# Time pargin
gem 'chronic'

# Logging
gem "lograge"

group :development, :test do
  # Call 'pry' anywhere in the code to stop execution and get a debugger console
  gem 'pry-rails'

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
end
