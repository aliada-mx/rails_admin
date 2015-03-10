class ApplicationMailer < ActionMailer::Base
  default :from => "hola@aliada.mx"

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

    mail to: to, subject: "", body: ""
  end

  def sendgrid_plain_mail(to: '', substitutions: {}, category: 'transactional', template_id: '', subject: '')
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

    mail to: to, subject: subject
  end
end
