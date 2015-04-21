namespace :db do
  desc "Remove wrong recurrences"
  task :find_wrong_recurrences => :environment do
	  Recurrence.active.all.each do |recurrence|
      count = recurrence.services.in_the_future.not_canceled.count
      if count <= 2
        puts "https://aliada.mx/perfil/#{recurrence.user.id}/visitas-proximas"
      end
    end
  end
end
