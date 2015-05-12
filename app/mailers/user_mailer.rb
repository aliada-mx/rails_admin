# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: user.email, subject: 'Bienvenido',
                           substitutions: {'-full_name-' => [ user.first_name ], '-password-' => [user.password]},
                           template_id: template_id
  end
  

  
  def service_confirmation(service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation]
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    sendgrid_template_mail to: service.user.email, subject: 'Confirmación de tu servicio',
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d de %B')],
      '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
  
  def service_confirmation_pwd(service, password)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation_password]
    
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    
    sendgrid_template_mail to: service.user.email,subject: 'Confirmación de tu servicio', 
    substitutions:
      {'-user_full_name-' => [ service.user.full_name  ],
      '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d')],
      '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-user_password-' => [password],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end

 
  def billing_receipt(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_receipt]
    service = Service.where(id: service.id).joins(:address).joins(:service_type).first
    score_service_url = score_service_users_url(service.user, service)
    
    if service.bill_by_reported_hours?
      service_worked_hours_text = "Horas reportadas de #{service.friendly_aliada_reported_begin_time} #{service.friendly_aliada_reported_end_time}"
    else
      service_worked_hours_text = ""
    end


    sendgrid_template_mail to: user.email,
      substitutions:
        {'-user_full_name-' => [ user.full_name  ],
        '-service_payment_last_4'=> [if service.payment_method then service.payment_method.last4 else "0000" end],
        '-service_date-' => [(I18n.l service.tz_aware_datetime, format: '%A %d de %B')],
        '-service_time-' => [(I18n.l service.tz_aware_datetime, format: '%I %p')] ,
        '-service_type_name-' => [service.service_type.display_name] ,
        '-service_address-' => [service.address.full_address],
        '-service_worked_hours-' => [service_worked_hours_text],
        '-service_friendly_total_hours-' =>[service.friendly_total_hours],
        '-service_price_per_hour-' => [service.service_type.price_per_hour],
        '-service_subtotal-' => [service.amount_to_bill],
        '-aliada_full_name-' => [service.aliada.full_name],
        '-service_score_1_url-' => ["#{score_service_url}?value=1"],
        '-service_score_2_url-' => ["#{score_service_url}?value=2"],
        '-service_score_3_url-' => ["#{score_service_url}?value=3"],
        '-service_score_4_url-' => ["#{score_service_url}?value=4"],
        '-service_score_5_url-' => ["#{score_service_url}?value=5"]},
      template_id: template_id

  end
  
  def payment_problem(user, payment_method)
    template_id = Setting.sendgrid_templates_ids[:billing_issue]
    
    sendgrid_template_mail to: user.email, subject: 'Problema con tu método de pago',
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
