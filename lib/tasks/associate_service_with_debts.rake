namespace :db do
  desc "Associate service with debts"
  task :associate_service_with_debts => :environment do

    puts "debts count #{Debt.all.count}"
    services_with_status_corrected = []

    services = Service.joins(:tickets).where('tickets.relevant_object_type = ?','Service')
                                      .where('tickets.relevant_object_id = services.id')
                                      .where('services.status != ?','paid')
                                      .where('tickets.category = ?','conekta_charge_failure') 
    services.each do |service|

      unless service.debts.any?
        services_with_status_corrected.push service

        Debt.find_or_create_by!(service: service,
                               user: service.user,
                               amount: service.amount_to_bill,
                               category: service.category)
      end
    end


    puts "#{ services_with_status_corrected.count } services_with_status_corrected"

    puts "debts count #{Debt.all.count}"
  end
end
