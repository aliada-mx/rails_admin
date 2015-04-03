class ServiceMailer < ApplicationMailer
include  ActionView::Helpers::DateHelper

  def aliada_changed(service)
    template_id = Setting.sendgrid_templates_ids[:aliada_changed]
     service = Service.where(id: service.id).joins(:user).joins(:service_type).first
    
    sendgrid_template_mail to: service.user.email, subject: 'Cambio de aliada',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-weekday-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone]},
    template_id: template_id
  end
  
  def hour_changed(service)
    template_id = Setting.sendgrid_templates_ids[:hour_changed]
     service = Service.where(id: service.id).joins(:user).joins(:service_type).first
    
    sendgrid_template_mail to: service.user.email, subject: 'Cambio la hora de tu servicio',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_friendly_datetime-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_current_hour-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
  
  def untimely_cancelation(service)
    template_id = Setting.sendgrid_templates_ids[:untimely_cancelation]
    
    service = Service.where(id: service.id).joins(:user).joins(:address).joins(:service_type).first
    
    sendgrid_template_mail to: service.user.email, subject: 'Has cancelado un servicio',
    substitutions:
      {'-user_full_name-' => [service.user.full_name],
      '-service_friendly_datetime-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_current_hour-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-late_cancelation_fee-' => [ "$100" ]},
    template_id: template_id
  end

  def address_changed(service, previous_address)
    template_id = Setting.sendgrid_templates_ids[:change_service_address]
    
    service = Service.where(id: service.id).joins(:user).joins(:service_type).first
    sendgrid_template_mail to: service.user.email, subject: 'Cambio de direccion',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-current_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-previous_address-' => [previous_address.full_address]},
    template_id: template_id 
    
   
  end
  
  def timely_cancelation(service)
    template_id = Setting.sendgrid_templates_ids[:timely_cancelation]
    service = Service.where(id: service.id).joins(:user).joins(:address).joins(:service_type).first
    
    sendgrid_template_mail to: service.user.email, subject:'Has cancelado un servicio',
    substitutions:
      {'-user_full_name-' => [service.user.full_name],
      '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name]},
    template_id: template_id
  end

  def reminder(service)
    template_id = Setting.sendgrid_templates_ids[:reminder]
    service = Service.where(id: service.id).joins(:user).joins(:address).joins(:service_type).first
    
    sendgrid_template_mail to: service.user.email, 
    subject: 'Recordatorio de visita',
    substitutions:
      {'-user_full_name-' => [service.user.full_name],
       '-aliada_full_name-'=> [service.aliada.full_name],
       '-aliada_phone-'=>[service.aliada.phone],
       '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-late_cancelation_fee-' => ["$100"],
      '-service_future_reference-' => [distance_of_time_in_words(service.datetime, Time.now)],
      '-service_type_name-' => [service.service_type.display_name]},
    template_id: template_id
  end
end
