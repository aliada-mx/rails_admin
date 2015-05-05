namespace :db do
  desc "Set cancelation on time"
  task :set_cancelation_on_time => :environment do
	  Service.all.each do |service|
      if service.status == 'canceled'
        if service.cancelation_fee_charged || service.owed?
          service.status = 'canceled_out_of_time'
        else
          service.status = 'canceled_in_time'
        end
        service.save!
      end
    end
  end
end
