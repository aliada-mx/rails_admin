namespace :db do
  desc "Deactivate recurrences without next_service"
  task :deactivate_recurrences_without_next_services => :environment do
	  Recurrence.all.each do |recurrence|
      recurrence.deactivate if recurrence.next_service.nil?
    end
  end
end
