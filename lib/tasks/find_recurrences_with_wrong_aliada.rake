namespace :db do
  desc "Find recurrences with wrong aliada"
  task :find_recurrences_with_wrong_aliada => :environment do
    probably_wrong = []
	  Recurrence.active.each do |recurrence|
      aliadas_count = Hash.new{ |h,k| h[k] = 0 }

      recurrence.services.not_canceled.in_the_future.each do |service|
        aliadas_count[service.aliada_id] += 1
      end

      most_probable_aliada = aliadas_count.max_by { |aliada_id, count| count }.try(:first)

      if most_probable_aliada && recurrence.aliada_id != most_probable_aliada
        probably_wrong.push recurrence
      end
    end

    probably_wrong.each do |recurrence|
      puts "https://aliada.mx/perfil/#{recurrence.user.id}/visitas-proximas"
    end
  end
end
