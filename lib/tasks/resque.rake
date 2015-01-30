require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task 'preload' => :environment

  task 'setup' => :environment do
    ENV['QUEUE'] = '*'
  end

  task 'setup_schedule' => :setup do
    require 'resque-scheduler'
    Resque.schedule = YAML.load_file('config/test_schedule.yml')
  end

  task :scheduler_setup => :setup_schedule
end
