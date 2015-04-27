namespace :db do
  desc "Fix recurrences data"
  task :fix_recurrences_aliada_id => :environment do
    fixed = []
    Recurrence.where(aliada_id: nil).each do |recurrence|
      last_service = recurrence.services.ordered_by_created_at.last
      if last_service && recurrence.aliada_id != last_service.aliada_id
        recurrence.aliada_id = last_service.aliada_id
        recurrence.save!

        fixed.push( recurrence )
      end
    end

    puts "fixed #{fixed.size} recurrences"
  end
end
