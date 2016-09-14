class ExportMailer < ApplicationMailer
  def results_email(user, attachment_filename, attachment_data)
    attachments[attachment_filename] = attachment_data
    mail(to: user.email, subject: 'Export Results')
  end
end
