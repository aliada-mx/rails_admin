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

      service.charge!
    end
  end
end
