require File.expand_path('../boot', __FILE__)

require 'rails/all'

# require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AliadaWebApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :es
    config.autoload_paths << Rails.root.join('lib')
    config.i18n.available_locales = [:es, :en]

    config.generators do |g|
      g.test_framework :rspec
    end

    Conekta.api_key = Rails.application.secrets.conekta_secret_key

    ActionMailer::Base.delivery_method = :smtp

    ActionMailer::Base.smtp_settings = {
      :address        => 'smtp.sendgrid.net',
      :port           => '587',
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => 'heroku.com',
      :enable_starttls_auto => true
    }
  end
end
