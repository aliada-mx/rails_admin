namespace :db do
    desc "Fix too small recurrences"
    task :fix_too_small_recurrences => :environment do

        ActiveRecord::Base.transaction do
            broken_recurrences = []

            Recurrence.active.all.each do |recurrence|
                if recurrence.services_for_user.count <= 3
                    broken_recurrences.push recurrence
                end
            end

            puts "there are #{broken_recurrences.size} incomplete recurrences"

            failed = []
            fixed = 0
            broken_recurrences.each do |recurrence|
               begin
                   puts "before fixing there are #{recurrence.services_for_user.count} services_for_user"
                   next_recurrence_datetime = recurrence.next_recurrence_with_hour_now_in_utc
                   puts "next_recurrence_datetime #{next_recurrence_datetime.weekday} weekday (#{recurrence.weekday})#{next_recurrence_datetime.hour} hour #{recurrence.hour}"
                   recurrence.datetime = next_recurrence_datetime 
                   recurrence.reschedule!(recurrence.aliada_id)
                   puts "recurrence #{recurrence.id} services count #{recurrence.services_for_user.count} recurrence aliada_id #{recurrence.aliada_id} services aliadas id #{recurrence.services_for_user.map { |s| s.aliada_id }}"
                   fixed +=1
               rescue AliadaExceptions::AvailabilityNotFound
                   failed.push recurrence
               end 
            end

            failed.each do |recurrence|
                puts "https://aliada.mx/perfil/#{recurrence.user.id}/visitas-proximas" 
                puts "weekday #{ recurrence.weekday }" 
                binding.pry
            end

            puts "fixed #{fixed}"
            puts "failed #{failed}"
            raise ActiveRecord::Rollback
        end
    end
end
