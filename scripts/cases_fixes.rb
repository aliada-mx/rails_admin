# -*- encoding : utf-8 -*-
u.services.each do |service|
  service.schedules.each do |schedule|
    if schedule.tz_aware_datetime.hour == 17
      schedule.user_id = 513
      schedule.service_id =  514
      schedule.recurrence_id = 2243
      schedule.save!
    end
  end
end

Schedule.find(13273).update_attributes(user_id: 513, service_id: 514, recurrence_id: 2243, status: 'booked')
Schedule.find(13274).update_attributes(user_id: 513, service_id: 514, recurrence_id: 2243, status: 'booked')
Schedule.find(5875).update_attributes(user_id: 513, service_id: 514, recurrence_id: 2243, status: 'booked')
Schedule.find(5876).update_attributes(user_id: 513, service_id: 514, recurrence_id: 2243, status: 'booked')
Schedule.find(2809).update_attributes(user_id: 513, service_id: 514, recurrence_id: 2243, status: 'booked')

r = Recurrence.find( 2243 )


schedules_ids = [ 1352, 1353, 1354, 1355, 1356, 1655, 2069 ]
schedules_ids.each do |id|
  schedule = Schedule.find id

  puts schedule.user.name
end

s.each do |schedule|
  next_service = schedule.next_schedule
  next_service = next_service.next_schedule
  next_service = next_service.next_schedule
  next_service = next_service.next_schedule
  next_service = next_service.next_schedule
  next_service = next_service.next_schedule
end
 
include AliadaSupport::DatetimeSupport
include Mixins::AvailabilityFindersMixin
def find_broken_continuity(service)
  datetime = service.datetime 
  ending_datetime = datetime + service.estimated_hours

  wdays_count = wdays_until_horizon(datetime.wday, starting_from: datetime)
  
  wdays_count.times do
    puts "Another week"
    schedules = Schedule.where(aliada_id: service.aliada_id)
                        .where('datetime >= ?', datetime)
                        .where('datetime <= ?', ending_datetime)

    schedules.each do |schedule|
      puts schedule.status
      puts schedule.aliada_id
    end

    datetime += 7.days
    ending_datetime += 7.days
  end

end

def enable_schedules_for_service(service_id: 788, aliada_id: 32, wday: 3, hour: 17)
  schedules = Schedule.where(aliada_id: 32).where("extract(dow from datetime::timestamp) = #{wday}").where("extract(hour from datetime::timestamp) = #{hour}")
  schedules = Schedule.where(aliada_id: 32).where("extract(dow from datetime::timestamp) = #{wday}").where("extract(hour from datetime::timestamp) = #{hour}")

  schedules.each do |schedule|
    schedule.service_id = service_id
    schedule.save!
  end
end


move
