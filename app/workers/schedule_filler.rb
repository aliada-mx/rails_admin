class ScheduleFiller 

  def self.queue
    :background_jobs
  end

  def self.perform
    self.fill_schedule
  end

  def self.fill_schedule
    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.days + 1.day
    
    ActiveRecord::Base.transaction do
      begin
        fill_aliadas_availability today_in_the_future

        insert_clients_schedule today_in_the_future, true
      rescue Exception => e
        Rails.logger.fatal e 
        Raygun.track_exception(e)
        raise e
      end
    end
  end

  def self.fill_schedule_for_specific_day specific_day
    
    ActiveRecord::Base.transaction do
      begin
        fill_aliadas_availability specific_day

        insert_clients_schedule specific_day, true 
      rescue Exception => e
        Rails.logger.fatal e 
        Raygun.track_exception(e)
        raise e
      end
    end
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

    # TODO: modify query with status for inactive recurrences
    base_service = user_recurrence.base_service
    unless base_service
      error = "Services have not been created for this user's recurrence"
      Rails.logger.fatal error
      raise error
    end

    # Compensate UTC 
    beginning_of_user_recurrence = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))

    base_service_attributes = base_service.shared_attributes
    service = Service.find_by(datetime: beginning_of_user_recurrence, user_id: user_recurrence.user_id)
    if not service
      service = Service.create!(base_service_attributes.merge({datetime: beginning_of_user_recurrence }))
    end
    service 
  end

  # client's recurrences, to book inside aliada's schedule 
  #TODO: REMOVE fix_total_hours flag AFTER MIGRATION FIX
  def self.insert_clients_schedule today_in_the_future, fix_total_hours = false

    Recurrence.active.each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        service = create_service_in_clients_schedule today_in_the_future, user_recurrence
        # Find the schedule in which the client will be assigned

        # Compensate UTC
        beginning_datetime = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))
        ending_datetime = beginning_datetime + user_recurrence.total_hours.hours

        schedules = Schedule.where("aliada_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, beginning_datetime, ending_datetime )
        if schedules.empty? 

          #TODO: REMOVE AFTER MIGRATION FIX
          if fix_total_hours

            # Aliadas fantasmas
            if not [43, 44].index user_recurrence.aliada_id

              #binding.pry
              error = "Aliada #{user_recurrence.aliada.first_name} #{user_recurrence.aliada.last_name} with empty or inactive schedules."
              Rails.logger.fatal error
              raise error

            end
            
          else
            error = "Aliada's future schedule was not found. Probably, the client's recurrence was not built considering the aliada's recurrence."
            Rails.logger.fatal error
            raise error
          end

        elsif (schedules.count < user_recurrence.total_hours)
          
          #TODO: REMOVE AFTER MIGRATION FIX
          if fix_total_hours

            if (user_recurrence.total_hours - schedules.count) > 2
              error = "Aliada's schedules difference #{(user_recurrence.total_hours - schedules.count)} is more than 2"
              Rails.logger.fatal error
              raise error
            end
          
            user_recurrence.update_attribute(:total_hours, schedules.count) 
          else
            error = "Aliada's schedules count #{schedules.count} didn't match number of user recurrence total hours #{user_recurrence.total_hours}"
            Rails.logger.fatal error
            raise error
          end
          
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end


  ##
  ##
  ## NO VALIDATION METHODS, TO BE RUN ONLY AFTER MIGRATION AND WHILE THE NEW WEBPAGE STABILIZES 
  ##
  ##
  
  def self.fix_recurrence_total_hours
    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.days + 1.day
    
    ActiveRecord::Base.transaction do
      begin
        fill_aliadas_availability today_in_the_future

        insert_clients_schedule today_in_the_future, true
      rescue Exception => e
        Rails.logger.fatal e 
        Raygun.track_exception(e)
        raise e
      end
    end
  end

  
  def self.fill_schedule_after_migration

    today_in_the_future = Time.zone.now.beginning_of_day + Setting.time_horizon_days.days + 1.day 

    ActiveRecord::Base.transaction do
      begin
        # Create schedules based on the Aliada Working Hours
        create_schedules_for_aliadas 

        fill_aliadas_availability_no_validation today_in_the_future

        insert_clients_schedule_no_validation today_in_the_future
      rescue Exception => e
        Rails.logger.fatal e
        Raygun.track_exception(e)
        raise e
      end
    end

  end

  def self.create_schedules_for_aliadas

    ( 0..( Setting.time_horizon_days - 1 ) ).each do |i|
      
      datetime = Time.zone.now.beginning_of_day + i.days

      Aliada.all.each do |aliada|
         
          aliada.aliada_working_hours.each do |awh|

            if awh.weekday == datetime.weekday
                
              beginning_of_recurrence = datetime.change(hour: awh.utc_hour(datetime))
              ending_of_recurrence = beginning_of_recurrence + awh.total_hours.hours

              ScheduleInterval.create_from_range_if_not_exists(beginning_of_recurrence, 
                                                             ending_of_recurrence,
                                                             conditions: {aliada_id: aliada.id, 
                                                                          recurrence_id: awh.id,
                                                                          zones: aliada.zones, 
                                                                          service_id: nil})
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

              schedule = Schedule.find_or_initialize_by(datetime: beginning_datetime + i.hours, aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, status: 'available', recurrence_id: user_recurrence.id)
              schedule.save!
              puts "CREATED SCHEDULE #{schedule.id}"
              schedules << schedule
            end 
          end
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end

  end

  def self.fix_service_id_in_schedules fixed_date

    incorrectas = 0
    incorrect_hash = {}
    Schedule.where("datetime >= ?", fixed_date).each do |schedule|
      
      if schedule.service_id
      
        schedule_datetime = schedule.datetime

        beginning_of_service_datetime = schedule.service.datetime
        ending_of_service_datetime = beginning_of_service_datetime + schedule.service.estimated_hours.to_f.ceil.hours + 2.hours

        if not (schedule_datetime >= beginning_of_service_datetime) && (schedule_datetime <= ending_of_service_datetime)
          # Deberían de ser los created_at del momento en que corrió el schedule filler
          incorrectas += 1
          incorrect_hash[schedule.service.id] = [] if not incorrect_hash[schedule.service.id]
          incorrect_hash[schedule.service.id] << schedule.id
        end

      end

    end

    puts "INCORRECTAS #{incorrectas}"
    return {incorrectas: incorrectas, incorrect_hash: incorrect_hash}
    
  end

  def self.fix_recurrence_ids_in_schedules

    actualizadas = 0
    conservadas = 0
    borradas = 0
    Schedule.all.each do |schedule|

      datetime_in_mexico_city = schedule.datetime.in_time_zone("Mexico City")
      if datetime_in_mexico_city.dst?
        datetime_in_mexico_city -= 1.hour 
      end
      weekday = datetime_in_mexico_city.weekday
      hour = datetime_in_mexico_city.hour
      
      recurrences = schedule.aliada.aliada_working_hours.where("weekday = ? and hour = ?", weekday, hour)
      if recurrences.empty?
        schedule.update_attribute(:recurrence_id, nil)
        borradas += 1
        next
      elsif recurrences.count > 1
        raise "Hay mas matches de aliadas working hours para la schedule"
      end
      recurrence_id = recurrences.first.id

      if schedule.recurrence_id != recurrence_id
        actualizadas += 1
        schedule.update_attribute(:recurrence_id, recurrence_id)
      else
        conservadas += 1
      end     

    end
    return "ACTUALIZADAS #{actualizadas} CONSERVADAS #{conservadas} BORRADAS #{borradas}"
  end

  def self.fix_duplicate_services
    services = Service.select(:datetime, :user_id).group(:datetime, :user_id).having("count(*) > 1")
    services.each do |service|
      duplicated_services = Service.where(datetime: service.datetime, user_id: service.user_id)

      if duplicated_services.count < 2
        raise "Error encontrando servicios duplicados"
      end

      duplicated_services.each do |dup_service|
        if dup_service.schedules.empty?
          dup_service.destroy
        end
      end
      
    end
  end
 
end
