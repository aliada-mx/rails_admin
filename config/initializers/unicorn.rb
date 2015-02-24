if Rails.env == 'production'
  # Switch to postgis adapter on gunicorn fork
  
  after_fork do |server, worker|
    if defined?(ActiveRecord::Base)
      config = ActiveRecord::Base.configurations[Rails.env] ||
        Rails.application.config.database_configuration[Rails.env]
      config['adapter'] = 'postgis'
      ActiveRecord::Base.establish_connection(config)
    end
  end
end
