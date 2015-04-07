module AliadaHelper
   def begin_hours_range(service)
     range_begin = (service.tz_aware_datetime - (1).hour).to_i
     range_end = (service.tz_aware_datetime + (1).hour).to_i
     return (range_begin .. range_end).step(15.minutes)
   end
   


   def end_hours_range(service)
     end_hours_minimum = service.estimated_hours - 2
    # if end_hours_minimum < 3
    # then
    #   end_hours_minimum = 3
    # end
    

     range_begin =  (service.tz_aware_datetime + end_hours_minimum.hour).to_i
     range_end =  (service.tz_aware_datetime + (service.estimated_hours + 2).hour).to_i
    
     return (range_begin .. range_end).step(15.minutes)
   end

end
