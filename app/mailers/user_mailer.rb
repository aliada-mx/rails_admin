class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: user.email,
                           substitutions: {'-full_name-' => [ user.first_name ], '-password-' => [user.password]},
                           template_id: template_id
  end
  

  
  def service_confirmation(service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation]
   # binding.pry
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
   # binding.pry
    sendgrid_template_mail to: service.user.email,
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
  
  def service_confirmation_pwd(service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation_password]
    
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    
    sendgrid_template_mail to: service.user.email,
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-user_password-' => [service.user.password],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end

 
  def billing_receipt(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_receipt]
    service = Service.where(id: service.id).joins(:address).joins(:service_type).first
    


    hours      = service.aliada_reported_end_time.hour - service.aliada_reported_begin_time.hour
    minutes    = service.aliada_reported_end_time.min  - service.aliada_reported_begin_time.min
    total_time = hours + minutes/60.0
    hours      = hours.floor
    minutes    = ((total_time - hours)*60).floor
    
    sendgrid_template_mail to: user.email,
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_payment_last_4'=> [if service.payment_method then service.payment_method.last4 else "0000" end],
      '-service_date-' => [(I18n.l service.datetime, format: '%A')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-aliada_reported_begin_time-' =>[(I18n.l service.aliada_reported_begin_time, format: '%H:%M %p')],
      '-aliada_reported_end_time-' =>[(I18n.l service.aliada_reported_end_time, format: '%H:%M %p')],
      '-service_friendly_total_hours-' =>[if hours < 3 then "3 hrs." else "#{hours} hrs con #{minutes} minutos" end],
      '-service_amount_to_bill-' => ["$#{service.service_type.price_per_hour}"],
      '-service_subtotal-' => ["$#{service.amount_to_bill}"],
      '-aliada_full_name-' => [service.aliada.full_name],
      '-service_score_1-' => ["#{score_service_url(service.id)}?value=1"],
      '-service_score_2-' => ["#{score_service_url(service.id)}?value=2"],
      '-service_score_3-' => ["#{score_service_url(service.id)}?value=3"],
      '-service_score_4-' => ["#{score_service_url(service.id)}?value=4"],
      '-service_score_5-' => ["#{score_service_url(service.id)}?value=5"]},
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
    sendgrid_template_mail to: user.email,
    substitutions:
      {'-user_full_name-' => [ user.full_name],
      '-current_address-' => [new_address.full_address],
      '-previous_address-' => [prev_address.full_address]},
    
    template_id: template_id
  end
end
