namespace :db do
  desc "Fix too small recurrences"
  task :fix_too_small_recurrences => :environment do

    failed = []
    fixed = 0
    ActiveRecord::Base.transaction do
      broken_recurrences = []

      Recurrence.active.all.each do |recurrence|
        if recurrence.services_for_user.count <= 3
          broken_recurrences.push recurrence
        end
      end

      puts "there are #{broken_recurrences.size} incomplete recurrences"

      fixed = 0
      broken_recurrences.each do |recurrence|

        recurrence_shared_attributes = recurrence.attributes_shared_with_service
        recurrence_shared_attributes.merge!({service_type: ServiceType.recurrent,
                                             status: 'aliada_assigned',
                                             recurrence_id: recurrence.id})

        datetime = recurrence.next_recurrence_now_in_time_zone.change(hour: recurrence.hour)

        4.times do |i|

          service = Service.find_by(datetime: datetime,
                                    user_id: recurrence.user_id,
                                    aliada_id: recurrence.aliada_id)
          if not service
            Service.create!(recurrence_shared_attributes.merge({ datetime: datetime }))
            fixed += 1
          end

          datetime += 7.days
        end
      end
      puts "fixed #{fixed}"
    end
  end
end
