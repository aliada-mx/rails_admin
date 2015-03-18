class CustomDeviseMailer < Devise::Mailer
  default :from => "info@aliada.mx"

  include Rails.application.routes.url_helpers
  
  
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
       '-password_change_url-' => [ "#{edit_user_password_url}?reset_password_token=#{token}" ],
       '-password_change_request_at-' => [ '' ]},
     template_id: template_id).deliver!
    # deliver! is necessary since Devise calls this method
  end
  
  def unlock_instructions(record, token, opts={})
    # code to be added here later
  end

end
