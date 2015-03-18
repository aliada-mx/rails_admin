# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#
require 'factory_girl_rails'
require_relative '../spec/support/schedules_helper'
include TestingSupport::SchedulesHelper

if ENV['clean']
  puts 'Truncating all the tables'
  require 'database_cleaner'

  DatabaseCleaner.clean_with(:truncation)
end


puts 'Creating:'

puts 'extras'

Extra.create!(name: 'Planchar (6pz)', hours: 0.5)
Extra.create!(name: 'Limpiar ventanas', hours: 0.5)
Extra.create!(name: 'Lavar a mano', hours: 1)
Extra.create!(name: 'Limpiar el refri', hours: 0.5)
Extra.create!(name: 'Limpiar el horno', hours: 0.5)
Extra.create!(name: 'Limpieza profunda', hours: 2)

puts 'one-time and recurrent service types'
ServiceType.create(name: 'one-time',
                   display_name: 'Sólo una vez',
                   price_per_hour: 105,
                   benefits: 'Prueba el servicio, Alta disponibilidad de las aliadas')

ServiceType.create(name: 'recurrent',
                   display_name: 'Cada Semana',
                   periodicity: 7,
                   price_per_hour: 79,
                   benefits: 'La misma Aliada en cada visita, Tu casa siempre limpia, El precio :)')


puts 'Admin user'
User.create!(first_name: 'Guillermo', last_name: 'Siliceo', email: 'guillermo.siliceo@gmail.com', role: 'admin', password: '12345678')

puts 'Aliada'
aliada = FactoryGirl.create(:aliada)

puts 'Zone'
zone = FactoryGirl.create(:zone)

puts '11800 postal code'
FactoryGirl.create(:postal_code, :zoned, zone: zone, number: '11800')

puts 'schedules for a week'

# Paste the contents of this function
def create_from_copypaste
  Schedule.destroy_all
  starting_datetime = Time.zone.now.change(hour: 13) # 7 am Mexico City Time
  aliada = Aliada.first
  zone = Zone.first

  require_relative 'spec/support/schedules_helper'
  include TestingSupport::SchedulesHelper

  6.times do |i|
    create_recurrent!(starting_datetime + i.day, hours: 6, periodicity: 7, conditions: {aliada: aliada, zone: zone})
  end
end
