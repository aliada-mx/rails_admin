require 'benchmark'
require 'launchy'
require 'ruby-prof'
require 'factory_girl_rails'

STARTING_DATETIME = Time.now.utc.change({hour: 13})
ENDING_DATETIME = STARTING_DATETIME + 6.hour

def current_aliada_number(schedules_number, aliadas_number, current_aliada, current_iteration)
  group_size = schedules_number / aliadas_number
  group_limit = group_size * current_aliada

  if current_iteration > group_limit
    return aliadas_number if current_iteration >= aliadas_number
    return current_aliada += 1
  else
    return current_aliada
  end
end

def setup(aliadas_number, schedules_number)
  aliadas = []

  aliadas_number.times do |i|
    aliadas.push FactoryGirl.create(:aliada, email: "user-#{i+1}@aliada.mx")
  end

  current_number = 1
  ActiveRecord::Base.transaction do
    schedules_number.times do |i|
      current_number = current_aliada_number(schedules_number, aliadas_number, current_number, i)

      # switch chosen aliada
      chosen_aliada = aliadas[current_number - 1]

      FactoryGirl.create(:schedule, datetime: STARTING_DATETIME + i.hour, status: 'available', aliada: chosen_aliada)
    end
  end
end

def tear_down
  Schedule.all.destroy_all
  User.all.destroy_all
end

def run
  report_file = "profiles/ScheduleChecker.html"
  six_hours_schedule_interval = ScheduleInterval.build_from_range(STARTING_DATETIME, ENDING_DATETIME)
  available_schedules = Schedule.available.ordered_by_user_datetime

  result = RubyProf.profile do
    ScheduleChecker.fits_in_schedules(available_schedules, six_hours_schedule_interval)
  end

  result.eliminate_methods!([/Integer#times/])
  result.eliminate_methods!([/Array#each/])
  printer = RubyProf::GraphHtmlPrinter.new(result)
  File.open(report_file, 'w') { |file| printer.print(file) }
  
  Launchy.open( File.join("file:///", File.expand_path(report_file)))
  # pp Benchmark.measure {
  # }
end

def perform(aliadas_number, schedules_number)
  tear_down
  setup(aliadas_number, schedules_number)
  run
end
