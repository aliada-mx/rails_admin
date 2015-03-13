class UserMailer < ApplicationMailer
  def welcome(user)
    template_id = Setting.sendgrid_templates_ids[:welcome]

    sendgrid_template_mail to: 'guillermo@aliada.mx',
                           substitutions: {'-full_name-' => [ user.name ], '-password-' => [ user.password ]},
                           template_id: template_id
  end

  def service_confirmation(user, service)
    template_id = Setting.sendgrid_templates_ids[:service_confirmation]

    sendgrid_template_mail to: 'guillermo@aliada.mx',
                                substitutions: {'-user_full_name-' => [ user.name ]},
                                template_id: template_id
  end
end
