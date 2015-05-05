

namespace :db do
  desc "Associate payments services"
  task :associate_payments_services => :environment do
    associated_services = []
	  Payment.all.each do |payment|
      next if payment.api_raw_response.nil?

      api_response = JSON.parse(payment.api_raw_response)

      if api_response['description'].include? 'Servicio'
        payment.service_id = api_response['reference_id'].to_i
        payment.save!

        associated_services.push(payment)
      end

    end
    puts "Associated services #{associated_services.count}"
  end
end
