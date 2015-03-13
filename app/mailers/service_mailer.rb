class ServiceMailer < ApplicationMailer

  def aliada_changed(service)
    template_id = Setting.sendgrid_templates_ids[:aliada_changed]
     service = service.joins(:users).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-weekday-' => [(I18n.l service.datetime, format: '%A %d')],
      '-time-' => [(I18n.l service.datetime, format: '%I %p')],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone]},
    template_id: template_id
  end
  
  def hour_changed(service)
    template_id = Setting.sendgrid_templates_ids[:hour_changed]
     service = service.joins(:users).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_friendly_datetime-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_current_hour-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
  
  def untimely_cancelation(service)
    template_id = Setting.sendgrid_templates_ids[:untimely_cancelation]
    
    service = service.joins(:users).joins(:addresses).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [service.user.full_name],
      '-service_friendly_datetime-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_current_hour-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-late_cancelation_fee-' => [ "$100" ]},
    template_id: template_id
  end

  def address_changed(service, previous_address)
    template_id = Setting.sendgrid_templates_ids[:change_service_address]
    
    service = service.joins(:users).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_hour-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-current_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-previous_address-' => [previous_address.full_address]},
    template_id: template_id 
    
   
  end
  
  def timely_cancelation
    template_id = Setting.sendgrid_templates_ids[:timely_cancelation]
  end

  def reminder
    template_id = Setting.sendgrid_templates_ids[:reminder]
  end
end
