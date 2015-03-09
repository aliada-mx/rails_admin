class SendgridMailer

  def self.plain_email(to: '', from: 'hola@aliada.mx', subject: '', text: '')
    api_user = SendgridToolkit.api_user
    api_key = SendgridToolkit.api_key

    SendgridToolkit::Mail.new(api_user, api_key).send_mail :to => to,
                                                           :from => from,
                                                           :subject => subject,
                                                           :text => text
  end

  def self.template_email(to: '', from: 'hola@aliada.mx', template_id: '', vars: {}, text: '')
    api_user = SendgridToolkit.api_user
    api_key = SendgridToolkit.api_key

    SendgridToolkit::Mail.new(api_user, api_key).send_mail :to => to, 
                                                           :subject => 'custom subject 2',
                                                           :from => from,
                                                           :text => 'custom text 2',
                                                           'x-smtpapi' => 
                                                             {
                                                               to: [ to ],
                                                               sub: vars,
                                                               # {
                                                               #   ":name": [
                                                               #     "Alice",
                                                               #     "Bob"
                                                               #   ],
                                                               #   ":price": [
                                                               #     "$4",
                                                               #     "$4"
                                                               #   ]
                                                               # },
                                                               category: [
                                                                 "Promotions"
                                                               ],
                                                               filters: {
                                                                 templates: {
                                                                   settings: {
                                                                     enable: 1,
                                                                     template_id: template_id
                                                                   }
                                                                 }
                                                               }
                                                             }
  end
end
