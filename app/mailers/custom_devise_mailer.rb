class CustomDeviseMailer < Devise::Mailer
default :from => "info@aliada.mx"

  include Rails.application.routes.url_helpers
  ###TODO implement devise
  def recover_password(user)
    template_id = Setting.sendgrid_templates_ids[:reset_password]
    
    service = Service.where(id: service.id).joins(:address).joins(:service_type).joins(:aliada).first
    
    sendgrid_template_mail to: 'alex@aliada.mx',
    substitutions:
      {'-user_full_name-' => [ user.full_name  ],
      '-password_change_url-' => [ service.aliada.full_name],
      '-password_change_request_at-' => [ '' ]},
    template_id: template_id
  end
def sendgrid_template_mail(to: '', substitutions: {}, category: 'transactional', template_id: '')
    header = Smtpapi::Header.new
    header.set_substitutions(substitutions)
    header.add_category(category)

    template_filter = {
        "templates" =>  {
          "settings" => {
            "enable" => 1,
            "template_id" => template_id
          }
        }
      }
    header.set_filters(template_filter)

    headers['X-SMTPAPI'] = header.to_json

    mail to: to
  end
####
 def confirmation_instructions(record, token, opts={})
    # code to be added here later
  end
  
  def reset_password_instructions(record, token, opts={})
    template_id = Setting.sendgrid_templates_ids[:reset_password]
    
    (sendgrid_template_mail to: record.email,
    substitutions:
      {'-user_full_name-' => [ record.full_name  ], ###Because we added this method in User
      '-password_change_url-' => [ edit_user_password_url],
      '-password_change_request_at-' => [ '' ]},
    template_id: template_id).deliver!
    # code to be added here later
  end
  
  def unlock_instructions(record, token, opts={})
    # code to be added here later
  end

end
