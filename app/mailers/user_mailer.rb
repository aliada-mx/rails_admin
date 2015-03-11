class UserMailer < ApplicationMailer
  # aliada-staging sendgrid test mail
  def test_mail
    id = '8ce0b5a8-8860-4c80-8f2d-1f6471bf0480'
    
    sendgrid_template_mail to: 'guillermo.siliceo@gmail.com',
                           substitutions: {subject: [ 'un tema' ], body: ['un tema']},
                           template_id: id
  end

  def welcome_email(user)
    id = 'c25504da-8cb2-49be-a4c4-16ca4de53b41'

    @user = user
    sendgrid_plain_mail to: 'guillermo.siliceo@gmail.com',
                             substitutions: {'-full_name-' => [ user.name ], '-password-' => [ user.password ]},
                             subject: 'Bienvenido a aliada',
                             template_id: id

  end
end
