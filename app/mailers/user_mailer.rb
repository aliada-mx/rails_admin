class UserMailer < ApplicationMailer
  def welcome(user)
    id = Setting.sendgrid_templates_ids[:welcome]

    @user = user
    sendgrid_template_mail to: 'guillermo.siliceo@gmail.com',
                           substitutions: {'-full_name-' => [ user.name ], '-password-' => [ user.password ]},
                           template_id: id

  end

  def service_confirmation(user, service)
    @user = user
    sendgrid_plain_mail to: 'guillermo.siliceo@gmail.com',
                             substitutions: {'-full_name-' => [ user.name ], '-password-' => [ user.password ]},
                             subject: 'Bienvenido a aliada',
                             template_id: id

  end
end
