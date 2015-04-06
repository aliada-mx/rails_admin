namespace :db do
  desc "Fixing operations cases "
  task :fix_case => :environment do
    case_name = ENV['CASE_NAME']
    
    puts "fixing #{case_name}"
    case case_name
      when 'recurrencias de diego arvizu'

        wednesday_recurrence_with_friday_services = Recurrence.find 2317
        
        wednesday_recurrence_with_friday_services.weekday = 'friday'

        wednesday_recurrence_with_friday_services.save!
    end
  end
end
