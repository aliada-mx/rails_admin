class TestJob
  
  def self.queue
    :background_jobs
  end

  def self.perform
    puts "WORKER JOB"
  end
end
