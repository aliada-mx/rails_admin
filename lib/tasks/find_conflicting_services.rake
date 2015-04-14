namespace :db do
  desc "Find conflicting services"
  task :find_conflicting_services => :environment do

    already_found = {}
    Service.in_the_future.not_canceled.ordered_by_created_at.each do |service|
      beginning = service.datetime
      ending = beginning  + service.estimated_hours.hours
      aliada_id = service.aliada_id

      conflicting = Service.not_canceled.where('datetime >= ?',beginning).where('datetime < ?',ending).where(aliada_id: aliada_id).where('id != ?', service.id)

      if conflicting.any?

        conflicting = conflicting.select do |s|
          if already_found.has_key? s.id
            false
          else
            already_found[s.id] = true

            service.user_id != s.user_id
          end
        end

        if conflicting.any?
          puts "for service #{service.created_at} #{service.id} there are #{conflicting.map { |s| [ s.datetime, s.id, s.created_at ] }} conflicting services"

        end
      end
    end

  end
end
