namespace :db do
  desc "Fix schedule filler services with extra info"
  task :fix_schedule_filler_services_info => :environment do
    puts 'Cleaning services created with wrong attributes'
    Service.where('datetime > ?',Time.zone.now).where('billable_hours is NOT NULL').each do |service|

      service.billable_hours = 0
      service.billed_hours = 0
      service.aliada_reported_begin_time = nil
      service.aliada_reported_end_time = nil
      service.cancelation_fee_charged = false
      service.confirmed = false

      begin
        service.save!
      rescue

      end
    end
  end
end
