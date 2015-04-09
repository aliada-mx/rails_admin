class ChangeReportedTimesToDatetime < ActiveRecord::Migration
  def up
    change_column :services, :aliada_reported_begin_time, "timestamp USING (datetime::date + aliada_reported_begin_time)"
    change_column :services, :aliada_reported_end_time, "timestamp USING (datetime::date + aliada_reported_end_time)"
  end
  
  def down
    change_column :services, :aliada_reported_begin_time, "time USING aliada_reported_begin_time"
    change_column :services, :aliada_reported_end_time, "time USING aliada_reported_end_time"
  end
  
  def data
    ###Here we fix the case where the aliada_end_time is before_the_begin_time
    services = Service.where("aliada_reported_end_time < aliada_reported_begin_time")

    services.each do |s|
      #When the times get fucked up, we straighten them
      puts "#{s.aliada_reported_end_time} #{s.user_id}"
      end_time = s.aliada_reported_end_time + 1.day
      s.aliada_reported_end_time = end_time
      puts "#{s.aliada_reported_end_time} #{s.user_id}"
      s.save!
    end
    
    #Arregla los billable hours,
    services = Service.where("billable_hours < 0").where(status: 'finished')
    services.each do |s|
      s.billable_hours = s.reported_hours
      s.save!
    end
  end
end
