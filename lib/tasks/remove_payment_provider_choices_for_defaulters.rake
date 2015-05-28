namespace :db do
  desc "Remove payment provider choices for defaulters"
  task :remove_payment_provider_choices_for_defaulters => :environment do
    ActiveRecord::Base.transaction do
      users_blocked = []

      User.all.each do |user|
        recurrences = user.recurrences.active.sort_by { |r| r.wday }

        should_break = false
        recurrences.each do |recurrence|
          if recurrence.services_for_user.any?
            should_break = true
          end
        end
        next if should_break 

        one_timers = user.services.one_timers.in_the_future.not_canceled.to_a

        if one_timers.any?
          next
        end

        previous_services = user.services.in_the_past.where('status NOT IN (?)',[:canceled_in_time, :canceled])
        
        previous_services.each do |service|
          if service.owed?
            user.payment_provider_choices.update_all(default: false)
            users_blocked.push(user)
          end 
        end
      end
      users_blocked.uniq!

      puts "puts #{ users_blocked.length } users_blocked "

      users_blocked.each do |user|
        puts "https://aliada.mx/perfil/#{user.id}/visitas-proximas  #{user.full_name} #{user.email}"
      end

      raise ActiveRecord::Rollback
    end
  end
end
