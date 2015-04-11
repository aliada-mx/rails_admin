# -*- encoding : utf-8 -*-
class ApplicationMailer < ActionMailer::Base
  default :from => "info@aliada.mx"

  def sendgrid_template_mail(to: '', subject:'',  substitutions: {}, category: 'transactional', template_id: '')
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


    mail(subject: subject ,  to:[ to ])


  end
end
