namespace :db do
  desc "Remove wrong recurrences"
  task :find_wrong_recurrences => :environment do
    recurrences = {}
	  Recurrence.active.all.each do |recurrence|
      count = recurrence.services.in_the_future.not_canceled.count
      if count <= 2
        recurrences[recurrence.user.id] = recurrence.user.id
      end
    end

    recurrences.each do |recurrence_id, user_id|
      puts "https://aliada.mx/perfil/#{user_id}/visitas-proximas"
    end
  end
end
