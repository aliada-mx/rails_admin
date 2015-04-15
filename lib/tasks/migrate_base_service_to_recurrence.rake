namespace :db do
  desc "Migrate base service to recurrence"
  task :migrate_base_service_to_recurrence => :environment do
    failed_recurrences = []
    recurrences_without_base_service = []
    ActiveRecord::Base.transaction do
      Recurrence.active.where(owner: 'user').each do |recurrence|
        base_service = recurrence.base_service
        if base_service
          shared_attributes = base_service.shared_attributes
        elsif recurrence.user
          shared_attributes = recurrence.user.services.first.shared_attributes

          recurrences_without_base_service.push(recurrence)
        else
          failed_recurrences.push(recurrence)
          next
        end
        shared_attributes.except!('service_type_id','price', 'recurrence_id')

        recurrence.update_attributes(shared_attributes)
      end

      # raise ActiveRecord::Rollback
    end
    puts "found #{recurrences_without_base_service.count} recurrences_without_base_service"
    puts "found #{failed_recurrences.count} failed_recurrences"

  end
end
