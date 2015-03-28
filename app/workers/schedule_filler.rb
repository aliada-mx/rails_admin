class ScheduleFiller 

  def self.queue
    :background_jobs
  end

  def self.perform
    self.fill_schedule
  end

  def self.fill_schedule
    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.days + 1.day

    fill_aliadas_availability today_in_the_future

    insert_clients_schedule today_in_the_future
  end

  # aliada's recurrences, to build the whole availability
  def self.fill_aliadas_availability today_in_the_future
    AliadaWorkingHour.active.each do |aliada_recurrence|
      if today_in_the_future.weekday == aliada_recurrence.weekday 

        #Compensate for UTC 
        beginning_of_recurrence = today_in_the_future.change(hour: aliada_recurrence.utc_hour(today_in_the_future))

        zones = aliada_recurrence.aliada.zones
        
        ( 0..(  aliada_recurrence.total_hours - 1 ) ).each do |i|
          
          if not Schedule.find_by(datetime: beginning_of_recurrence + i.hours, aliada_id: aliada_recurrence.aliada_id)

            schedule_intervals = ScheduleInterval.build_from_range(beginning_of_recurrence + i.hours, 
                                                             beginning_of_recurrence + i.hours + 1.hours,
                                                             from_existing: false,
                                                             conditions: {aliada_id: aliada_recurrence.aliada_id, 
                                                                          recurrence_id: aliada_recurrence.id,
                                                                          zones: zones, 
                                                                          service_id: nil})

            schedule_intervals.persist!
          end
        end
      end
    end
  end

  # creates service inside aliada's schedule, based on the client's recurrence
  def self.create_service_in_clients_schedule today_in_the_future, user_recurrence 

    # Create service with the most recently modified one for that recurrence
    services = Service.where("recurrence_id = ?", user_recurrence.id).order("updated_at DESC")
    if services.empty?
      error = "Services have not been created for this user's recurrence"
      Rails.logger.fatal error
      raise error
    end

    # Compensate UTC 
    beginning_of_user_recurrence = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))

    service = services.first.dup
    service.update_attribute(:datetime, beginning_of_user_recurrence)
    service 
  end

  # client's recurrences, to book inside aliada's schedule 
  def self.insert_clients_schedule today_in_the_future

    Recurrence.active.each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        service = create_service_in_clients_schedule today_in_the_future, user_recurrence
        # Find the schedule in which the client will be assigned

        # Compensate UTC
        beginning_datetime = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))
        ending_datetime = beginning_datetime + user_recurrence.total_hours.hours

        schedules = Schedule.where("aliada_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, beginning_datetime, ending_datetime )
        if schedules.empty?
          error = "Aliada's future schedule was not found. Probably, the client's recurrence was not built considering the aliada's recurrence."
          Rails.logger.fatal error
          raise error
        elsif (schedules.count < user_recurrence.total_hours)
          error = "Aliada's schedules didn't match number of user recurrence total hours"
          Rails.logger.fatal error
          raise error
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end


  ##NO VALIDATION METHODS, TO BE RUN ONLY AFTER MIGRATION##
  #
  #
  
  def self.fill_schedule_after_migration
    
    # Create schedules based on the Aliada Working Hours
    create_schedules_for_aliadas 

    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.days + 1.day 

    fill_aliadas_availability_no_validation today_in_the_future

    insert_clients_schedule_no_validation today_in_the_future

  end

  def self.create_schedules_for_aliadas

    ( 0..( Setting.time_horizon_days - 1 ) ).each do |i|
      
      datetime = Time.zone.now.beginning_of_day + i.days

      Aliada.all.each do |aliada|
         
          aliada.aliada_working_hours.each do |awh|

            if awh.weekday == datetime.weekday
                
              beginning_of_recurrence = datetime.change(hour: awh.utc_hour(datetime))
              ending_of_recurrence = beginning_of_recurrence + awh.total_hours.hours

              begin 
              ScheduleInterval.create_from_range_if_not_exists(beginning_of_recurrence, 
                                                             ending_of_recurrence,
                                                             conditions: {aliada_id: aliada.id, 
                                                                          recurrence_id: awh.id,
                                                                          zones: aliada.zones, 
                                                                          service_id: nil})
              rescue Exception => e
                binding.pry
              end
            end
      
          end

      end

    end

  end

  # aliada's recurrences, to build the whole availability
  def self.fill_aliadas_availability_no_validation today_in_the_future 
    AliadaWorkingHour.active.each do |aliada_recurrence|
      if today_in_the_future.weekday == aliada_recurrence.weekday 

        #Compensate for UTC 
        beginning_of_recurrence = today_in_the_future.change(hour: aliada_recurrence.utc_hour(today_in_the_future))

        zones = aliada_recurrence.aliada.zones

        ( 0..(  aliada_recurrence.total_hours - 1 ) ).each do |i|

          if not Schedule.find_by(datetime: beginning_of_recurrence + i.hours, aliada_id: aliada_recurrence.aliada_id)

            begin
            schedule_intervals = ScheduleInterval.build_from_range(beginning_of_recurrence + i.hours, 
                                                             beginning_of_recurrence + i.hours + 1.hours,
                                                             from_existing: false,
                                                             conditions: {aliada_id: aliada_recurrence.aliada_id, 
                                                                          recurrence_id: aliada_recurrence.id,
                                                                          zones: zones, 
                                                                          service_id: nil})
            schedule_intervals.persist!
            rescue Exception => e
              binding.pry
            end

          end

        end

      end
    end
  end

  # client's recurrences, to book inside aliada's schedule 
  def self.insert_clients_schedule_no_validation today_in_the_future 

    Recurrence.active.where("user_id is not null").each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        service = create_service_in_clients_schedule today_in_the_future, user_recurrence

        # Compensate for UTC
        beginning_datetime = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))
        ending_datetime = beginning_datetime + user_recurrence.total_hours.hours
        
        # Find the schedule in which the client will be assigned
        schedules = Schedule.where("aliada_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, beginning_datetime, ending_datetime )
        if schedules.empty? or (schedules.count < user_recurrence.total_hours)
          schedules = []
          #CREATE SCHEDULES
          ( 0..( user_recurrence.total_hours - 1 ) ).each do |i|
            if not Schedule.find_by(datetime: beginning_datetime + i.hours, aliada_id: user_recurrence.aliada_id)
              begin
              schedule = Schedule.find_or_initialize_by(datetime: beginning_datetime + i.hours, aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, status: 'available', recurrence_id: user_recurrence.id)
              schedule.save!
              puts "CREATED SCHEDULE #{schedule.id}"
              schedules << schedule
              rescue Exception => e
                binding.pry
              end
            end 
          end
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end

end
