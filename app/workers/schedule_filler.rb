class ScheduleFiller 
  
  def self.queue
    :background_jobs
  end

  def self.perform
    self.fill_schedule
  end

  def self.fill_schedule
    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.day + 1.day 

    fill_aliadas_availability today_in_the_future

    insert_clients_schedule today_in_the_future
  end

  # aliada's recurrences, to build the whole availability
  def self.fill_aliadas_availability today_in_the_future
    AliadaWorkingHour.all.each do |aliada_recurrence|
      if today_in_the_future.weekday == aliada_recurrence.weekday 
        beggining_of_recurrence = today_in_the_future + aliada_recurrence.hour.hour
        ending_of_recurrence = today_in_the_future + aliada_recurrence.hour.hour + aliada_recurrence.total_hours.hour

        schedule_intervals = ScheduleInterval.build_from_range(beggining_of_recurrence, 
                                                               ending_of_recurrence,
                                                               from_existing: false,
                                                               conditions: {aliada_id: aliada_recurrence.aliada_id, 
                                                                            zone_id: aliada_recurrence.zone_id, 
                                                                            service_id: nil})
        schedule_intervals.persist!
      end
    end
  end

  # creates service inside aliada's schedule, based on the client's recurrence
  def self.create_service_in_clients_schedule today_in_the_future, user_recurrence

    # Create service with the most recently modified one for that recurrence
    # TODO: modify query with status for inactive recurrences
    services = Service.where("recurrence_id = ?", user_recurrence.id).order("updated_at DESC")
    if services.empty?
      error = "Services have not been created for this user's recurrence"
      Rails.logger.fatal error
      raise error
    end
    service = services.first.dup
    service.update_attribute(:datetime, (today_in_the_future + user_recurrence.hour.hour))
    service 
  end

  # client's recurrences, to book inside aliada's schedule 
  def self.insert_clients_schedule today_in_the_future

    Recurrence.all.each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        service = create_service_in_clients_schedule today_in_the_future, user_recurrence
        
        # Find the schedule in which the client will be assigned
        schedules = Schedule.where("aliada_id = ? AND zone_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, user_recurrence.zone_id, (today_in_the_future + user_recurrence.hour.hour),  (today_in_the_future + user_recurrence.hour.hour + user_recurrence.total_hours.hour) )
        if schedules.empty? 
          error = "Aliada's future schedule was not found. Probably, the client's recurrence was not built considering the aliada's recurrence."
          Rails.logger.fatal error
          raise error
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules!(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end


  ##NO VALIDATION METHODS, TO BE RUN ONLY AFTER MIGRATION
  
  def self.fill_schedule_after_migration
    
    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.day + 1.day 

    fill_aliadas_availability_no_validation today_in_the_future

    insert_clients_schedule_no_validation today_in_the_future

  end

  # aliada's recurrences, to build the whole availability
  def self.fill_aliadas_availability_no_validation today_in_the_future
    AliadaWorkingHour.all.each do |aliada_recurrence|
      if today_in_the_future.weekday == aliada_recurrence.weekday 
        beggining_of_recurrence = today_in_the_future + aliada_recurrence.hour.hour
        ending_of_recurrence = today_in_the_future + aliada_recurrence.hour.hour + aliada_recurrence.total_hours.hour

        if aliada_recurrence.zone_id

          schedule_intervals = ScheduleInterval.build_from_range(beggining_of_recurrence, 
                                                               ending_of_recurrence,
                                                               from_existing: false,
                                                               conditions: {aliada_id: aliada_recurrence.aliada_id, 
                                                                            zone_id: aliada_recurrence.zone_id, 
                                                                            service_id: nil})
          schedule_intervals.persist!
        end
      end
    end
  end

  # client's recurrences, to book inside aliada's schedule 
  def self.insert_clients_schedule_no_validation today_in_the_future

    Recurrence.where("user_id is not null").each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        service = create_service_in_clients_schedule today_in_the_future, user_recurrence
        
        # Find the schedule in which the client will be assigned
        schedules = Schedule.where("aliada_id = ? AND zone_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, user_recurrence.zone_id, (today_in_the_future + user_recurrence.hour.hour),  (today_in_the_future + user_recurrence.hour.hour + user_recurrence.total_hours.hour) )
        if schedules.empty? 
          #CREATE SCHEDULE
          zone_id = User.find(user_recurrence.user_id).addresses.first.postal_code.zones.first.id
          schedule = Schedule.find_or_create_by(datetime: (today_in_the_future + user_recurrence.hour.hour), aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, status: 'available', zone_id: zone_id )
          puts "CREATED SCHEDULE #{schedule.id}"
          schedules = [schedule]
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules!(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end  

end
