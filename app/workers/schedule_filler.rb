# -*- encoding : utf-8 -*-
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

        insert_clients_schedule today_in_the_future
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

        insert_clients_schedule specific_day
      rescue Exception => e
        Rails.logger.fatal e 
        Raygun.track_exception(e)
        raise e
      end
    end
  end

  # aliada's recurrences, to build the whole availability
  def self.fill_aliadas_availability today_in_the_future
    AliadaWorkingHour.active.each do |awh|

      if today_in_the_future.weekday == awh.utc_weekday(today_in_the_future)

        #Compensate for UTC 
        beginning_of_recurrence = today_in_the_future.change(hour: awh.utc_hour(today_in_the_future))

        if not Schedule.find_by(datetime: beginning_of_recurrence, aliada_id: awh.aliada_id)

          Schedule.create(datetime: beginning_of_recurrence,
                          aliada_id:  awh.aliada_id,
                          aliada_working_hour: awh)

        end
      end
    end
  end

  # creates service inside aliada's schedule, based on the client's recurrence
  def self.create_service_in_clients_schedule( today_in_the_future, user_recurrence )
    # Compensate UTC 
    beginning_of_user_recurrence = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))

    recurrence_shared_attributes = user_recurrence.attributes_shared_with_service
    recurrence_shared_attributes.merge!({service_type: ServiceType.recurrent,
                                         status: 'aliada_assigned',
                                         recurrence_id: user_recurrence.id})

    service = Service.find_by(datetime: beginning_of_user_recurrence, user_id: user_recurrence.user_id)
    if not service
      service = Service.new(recurrence_shared_attributes.merge({datetime: beginning_of_user_recurrence }))
    end
    service.save!
    service 
  end

  # client's recurrences, to book inside aliada's schedule 
  def self.insert_clients_schedule( today_in_the_future )

    Recurrence.active.each do |user_recurrence| 

      if today_in_the_future.weekday == user_recurrence.utc_weekday(today_in_the_future)

        # Compensate UTC
        beginning_datetime = today_in_the_future.change(hour: user_recurrence.utc_hour(today_in_the_future))
        ending_datetime = beginning_datetime + user_recurrence.total_hours.hours

        schedules = Schedule.where("aliada_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, beginning_datetime, ending_datetime )
        if schedules.count < user_recurrence.total_hours
          error = "Servicio no se pudo crear porque las horas totales en la recurrencia del usuario excenden las que se tienen con su aliada. Aliada #{user_recurrence.aliada.first_name} #{user_recurrence.aliada.last_name}, Usuario #{user_recurrence.user.first_name} #{user_recurrence.user.last_name}, horario - #{user_recurrence.weekday} #{user_recurrence.hour}:00 hrs, horas totales #{user_recurrence.total_hours}"
          
          Ticket.create_error(relevant_object: user_recurrence,
                              category: 'schedule_filler_error',
                              message: error)
          next
        elsif schedules.count < user_recurrence.total_hours
          error = "Las #{schedules.count} horas de servicio de la aliada no concuerdan con las horas totales de la recurrencia #{user_recurrence.total_hours}"
          Rails.logger.fatal error
          Ticket.create_error(relevant_object: user_recurrence,
                              category: 'schedule_filler_error',
                              message: error)
        end
        
        service = create_service_in_clients_schedule today_in_the_future, user_recurrence

        if service
          # Assign the client to the aliada's schedule
          ScheduleInterval.new(schedules).book_schedules(aliada_id: user_recurrence.aliada_id,
                                                         user_id: user_recurrence.user_id,
                                                         recurrence_id: user_recurrence.id,
                                                         service_id: service.id)
        end

      end
    end
  end
  
end
