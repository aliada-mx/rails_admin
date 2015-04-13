namespace :db do
  desc "Fix too small recurrences"
  task :fix_too_small_recurrences => :environment do

    broken_recurrences = []
    ok_recurrences = Hash.new{ |h,k| h[k] = {} }

    User.all.each do |user|

      recurrent_services = user.services.recurrent.not_canceled.to_a.uniq { |s| s.recurrence_id }.select { |s| s.recurrence.try(:active?) }
      
      recurrent_services.each do |service|
        next_service = service.recurrence.next_service

        if next_service.nil?
          broken_recurrences.push(service.recurrence)
        elsif service.recurrence.active? && service.not_canceled?
          ok_recurrences[user.id][service.recurrence.wday_hour] = service.recurrence
        end

      end
    end

    puts "there are #{broken_recurrences.count} broken_recurrences"

    puts "reasining recurrence to services in broken recurrences"

    broken_recurrences.each do |recurrence|
      recurrence.services.each do |service|
        ok_recurrence = ok_recurrences[service.user.id][service.wday_hour]

        service.recurrence = ok_recurrence
        service.save!
      end
    end

  end
end
