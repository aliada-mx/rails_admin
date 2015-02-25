# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

puts 'creating extras'

Extra.destroy_all
Extra.create!(name: 'Planchar (12pz)', hours: 1)
Extra.create!(name: 'Limpiar ventanas', hours: 1)
Extra.create!(name: 'Lavar ropa', hours: 1)
Extra.create!(name: 'Limpiar el refri', hours: 1.5)
Extra.create!(name: 'Limpiar el horno', hours: 0.5)
Extra.create!(name: 'Limpieza profunda', hours: 2)
