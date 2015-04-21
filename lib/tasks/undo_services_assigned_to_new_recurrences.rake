namespace :db do
  desc "Undo services assigned to invented recurrences"
  task :undo_services_assigned_to_invented_recurrences => :environment do
	
    starting_datetime = ActiveSupport::TimeZone['Etc/GMT+6'].parse('dom, 12 abr 2015 09:20')
    ending_datetime = ActiveSupport::TimeZone['Etc/GMT+6'].parse('dom, 12 abr 2015 09:40')

    versions = PaperTrail::Version.where('created_at >= ?', starting_datetime).where('created_at <= ?', ending_datetime).where(item_type: 'Service').where('object_changes LIKE ?','%recurrence_id%')

    changed = []
    recurrences_activated = []

    versions.each do |version|
      if version.next
        correct_service = version.next.reify
      end
      whodunnit = version.whodunnit
      service = Service.find(version.item_id)

      next if service.canceled? || service.datetime < Time.zone.now

      if correct_service && whodunnit.nil?
        recurrence = correct_service.recurrence

        if recurrence.inactive?
          recurrence.activate
          recurrences_activated.push(recurrence)
        end

        changed.push(service)
        service.recurrence = recurrence
        service.save!
      end
    end

    puts "corrected #{ changed.size } services"
    puts "activated #{ recurrences_activated.size } recurrences"
  end
end
