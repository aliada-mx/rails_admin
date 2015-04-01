def iterate_in_hour_steps(start, end_)
  Enumerator.new { |y| loop { y.yield start; start += 1.hour } }.take_while { |d| d < end_ }
end

namespace :db do
  desc "Getting busy the aliadas schedules"
    task :busy_aliadas_schedules => :environment do
      aliadas_names = [ '"Aide"', 'Feliciana', 'Gloria Patricia', 'Blanca Silvia', 'Lucía Baldelamar', 'Delia', 'Cinthia Viridiana', 'Marcela', 'Araceli', 'Alma Gabriela', 'Erika', 'Flor', 'Mireya', 'Flor C', 'Carolina', 'Violeta', 'Lucero ', 'Elizabeth', 'Petra', 'Carmen Valdez', 'Claudia Valeria', 'Jaqueline', 'Leonila', 'María Esther', 'María del Carmen', 'Reyna', 'Paula Angélica', 'Socorro', 'Josefina Jimenez', 'María Teresa', 'Julia Noemí', 'Claudia Inés', 'Magnolia', 'Josefina Sánchez', 'María Guadalupe', 'Ana Laura', 'Anabel', 'Marina', 'Elizabeth Soledad', 'Alma Beatriz', 'Martha', 'Selene', 'Norma', ]
      dates = ['2 april', '3 april', '4 april', '5 april'].map { |d| ActiveSupport::TimeZone["Mexico City"].parse(d) }

      aliadas_names.each do |full_name|
        name = full_name.split(' ')

        aliada = Aliada.where(first_name: name.first)
        
        dates.each do |date|

        end
      end
    end
  end
end
