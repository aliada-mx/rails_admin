class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: 'alex@aliada.mx',
                           substitutions: {'-full_name-' => [ user.first_name ], '-password-' => [ user.name ]},
                           template_id: template_id
  end

  def service_confirmation(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation]
    
    service = service.joins(:addresses).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A')],
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
    
    service = service.joins(:addresses).joins(:service_types).joins(:aliadas)
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-service_date-' => [(I18n.l service.datetime, format: '%A')],
      '-service_time-' => [(I18n.l service.datetime, format: '%I %p')] ,
      '-service_address-' => [service.address.full_address],
      '-service_type_name-' => [service.service_type.display_name],
      '-aliada_full_name-' => [ service.aliada.full_name],
      '-aliada_phone-' => [service.aliada.phone],
      '-service_cancelation_limit_hours-' => [ 24 ]},
    template_id: template_id
  end
end
