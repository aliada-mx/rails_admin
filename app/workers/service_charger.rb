# -*- encoding : utf-8 -*-
class ServiceCharger 
  
  def self.queue
    :charges
  end

  def self.perform(services_ids)
    self.charge_services(services_ids)
  end

  def self.charge_services(services_ids)
    services_ids.each do |service_id|
      service = Service.find(service_id)

      begin
        service.charge!
      rescue Conekta::Error, Conekta::ProcessingError => exception
        product = OpenStruct.new({amount: service.amount_to_bill,
                                 description: 'Servicio aliada',
                                 category: 'service',
                                 id: service.id})

        service.create_charge_failed_ticket(service.user, service.amount_to_bill, exception)

        service.user.register_debt(product, service)
      end
    end
  end
end
