# -*- coding: utf-8 -*-

namespace :db do
  desc "Getting busy the aliadas schedules"
    task :busy_aliadas_schedules => :environment do
      aliadas_names = [ 'Aide', 'Feliciana', 'Gloria Patricia', 'Blanca Silvia', 'Delia', 'Cinthia Viridiana', 'Marcela', 'Araceli', 'Alma Gabriela', 'Erika', 'Flor', 'Mireya',  'Carolina', 'Violeta', 'Lucero Lizeth', 'Elizabeth', 'Petra',  'Claudia Valeria', 'Jaqueline Andrea', 'Leonila', 'María Esther', 'María del Carmen', 'Reyna', 'Paula Angélica', 'Socorro',  'María Teresa', 'Julia Noemí', 'Claudia Inés', 'Magnolia',  'Maria Guadalupe', 'Ana Laura', 'Anabel', 'Marina', 'Elizabeth Soledad', 'Alma Beatriz', 'Martha', 'Selene', 'Norma Alicia' ]
      dates = ['2 april', '3 april', '4 april', '5 april'].map { |d| ActiveSupport::TimeZone["Mexico City"].parse(d) }

    aliadas_names.each do |name|
      #name = full_name.split(' ')
      
      aliada = Aliada.find_by(first_name: name)
      
      dates.each do |date|
        Schedule.where(:datetime => date.beginning_of_day.utc..date.end_of_day.utc, aliada_id: aliada.id).each do |sch|
          sch.enable_booked
          sch.save!
        end
      end
    end
  end
end
