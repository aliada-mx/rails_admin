class ReminderSender

  def self.queue
    :background_jobs
  end
  
  def self.perform
    self.send_reminders
  end

  def self.services_to_remind
    day = ActiveSupport::TimeZone["Mexico City"].today + 1.day
    services = Service.where(:datetime => day.beginning_of_day..day.end_of_day)
    
    return services
  end
  
  def self.send_reminders
    services = self.services_to_remind
    services.each do |s|
      ServiceMailer::reminder(s).deliver!
    end
  end

end
