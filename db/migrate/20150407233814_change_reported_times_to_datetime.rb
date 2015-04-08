class ChangeReportedTimesToDatetime < ActiveRecord::Migration
  def up
    change_column :services, :aliada_reported_begin_time, "timestamp USING (datetime::date + aliada_reported_begin_time)"
    change_column :services, :aliada_reported_end_time, "timestamp USING (datetime::date + aliada_reported_end_time)"
  end
  
  def down
    
  end
  
  def data
    ###Here we fix the case where the aliada_end_time is before_the_begin_time
    services = Service.where("aliada_reported_end_time < aliada_reported_begin_time")
    
    services.each do |s|
      #swap
      begin_time = s.aliada_reported_begin_time
      end_time = s.aliada_reported_end_time
      
      s.aliada_reported_begin_time = end_time
      s.aliada_reported_end_time = begin_time
      s.save!
    end
  end
end
