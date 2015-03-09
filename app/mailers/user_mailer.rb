class UserMailer < ApplicationMailer
  # aliada-staging sendgrid test mail
  def test_mail
    id = '8ce0b5a8-8860-4c80-8f2d-1f6471bf0480'
    
    sendgrid_template_mail to: 'guillermo.siliceo@gmail.com',
                           substitutions: {subject: [ 'un tema' ], body: ['un tema']},
                           template_id: id
  end

  def welcome_email(user)
    id = '371f2a77-45c5-4644-b3be-0639395a4ca3'

    @user = user
    sendgrid_plain_mail to: 'guillermo.siliceo@gmail.com',
                             substitutions: {'-name-' => [ user.name ], '-password-' => [ user.password ]},
                             subject: 'Bienvenido a aliada',
                             template_id: id

  end
end
