class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: 'alex@aliada.mx',
                           substitutions: {'-full_name-' => [ user.first_name ], '-password-' => [ user.name ]},
                           template_id: template_id
  end
  

  
  def service_confirmation(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation]
   # binding.pry
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
   # binding.pry
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
  
  def service_confirmation_pwd(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation_password]
    
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end

  ###todo implement billing hours
  def billing_receipt(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_receipt]
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    
    hours = service.aliada_reported_end_time.hours - service.aliada_reported_begin_time.hour
    minutes = service.aliada_reported_end_time.min - service.aliada_reported_begin_time.min
    total_time = hours + minutes/60.0
    hours = hours.floor
    minutes = ((total_time - hours)*60).floor
   

    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-aliada_reported_begin_time-' =>[(I18n.l service.aliada_reported_begin_time, format: '%H:%M %p')],
      '-aliada_reported_end_time-' =>[(I18n.l service.aliada_reported_end_time, format: '%H:%M %p')],
      '-service_friendly_total_hours-' =>["#{hours} hrs con #{minutes} minutos"],
      '-service_amount_to_bill' => [service.price],
      '-service_subtotal-' => [service.amount_to_bill],
      '-aliada_full_name-' => [service.aliada.full_name]},
    template_id: template_id
    
  end
  
  def payment_problem(user, payment_method)
    template_id = Setting.sendgrid_templates_ids[:billing_issue]
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_payment_last_4-' => [ payment_method.last4]},
    template_id: template_id
  end

  def user_address_changed(user,new_address, prev_address)
    template_id = Setting.sendgrid_templates_ids[:change_client_address]
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_address],
      '-current_address-' => [new_address.full_address],
      '-previous_address-' => [prev_address.full_address]},
    
    template_id: template_id
  end
end
