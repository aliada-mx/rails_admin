class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: 'alex@aliada.mx',
                           substitutions: {'-full_name-' => [ user.first_name ], '-password-' => [ user.name ]},
                           template_id: template_id
  end
  
###TODO implement devise
  def recover_password(user)
     template_id = Setting.sendgrid_templates_ids[:reset_password]
    
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-password_change_url-' => [ service.aliada.full_name],
      '-password_change_request_at-' => [ 24 ]},
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
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-aliada_reported_begin_time-' =>[(I18n.l service.aliada_reported_begin_time, format: '%H:%M %p')],
      '-aliada_reported_end_time-' =>[(I18n.l service.aliada_reported_begin_time, format: '%H:%M %p')],
      '-service_friendly_total_hours-' =>[],
      '-service_amount_to_bill' => [],
      '-service_subtotal-' => [],
      '-aliada_full_name-' => [ service.aliada.full_name]},
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
