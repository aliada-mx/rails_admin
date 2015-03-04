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


puts 'creating extras'

Extra.destroy_all
Extra.create!(name: 'Planchar (6pz)', hours: 0.5)
Extra.create!(name: 'Limpiar ventanas', hours: 0.5)
Extra.create!(name: 'Lavar a mano', hours: 1)
Extra.create!(name: 'Limpiar el refri', hours: 0.5)
Extra.create!(name: 'Limpiar el horno', hours: 0.5)
Extra.create!(name: 'Limpieza profunda', hours: 2)

puts 'creating service types'
ServiceType.destroy_all
ServiceType.create(name: 'one-time',
                   display_name: 'Sólo una vez',
                   price_per_hour: 105,
                   benefits: 'Prueba el servicio, Alta disponibilidad de las aliadas')

ServiceType.create(name: 'recurrent',
                   display_name: 'Cada Semana',
                   periodicity: 7,
                   price_per_hour: 79,
                   benefits: 'La misma Aliada en cada visita, Tu casa siempre limpia, El precio :)')

puts 'Creating users'
User.destroy_all
User.create!(first_name: 'Guillermo', last_name: 'Silice', email: 'guillermo.siliceo@gmail.com', role: 'admin', password: '12345678')

puts 'creating data for testing the frontend testing'

Aliada.destroy_all
puts 'creating aliada'
aliada = FactoryGirl.create(:aliada)

Zone.destroy_all
puts 'creating zone'
zone = FactoryGirl.create(:zone)

PostalCode.destroy_all
puts 'creating postal_code'
postal_code = FactoryGirl.create(:postal_code, :zoned, zone: zone, code: '11800')

Schedule.destroy_all
create_recurrent!(Time.zone.now.change({hour: 7}), hours: 12, periodicity: 7, conditions: {aliada: aliada, zone: zone})
