class ScheduleFiller 
  
  def self.queue
    :background_jobs
  end

  def self.perform
    Recurrence.fill_schedule
  end
end
