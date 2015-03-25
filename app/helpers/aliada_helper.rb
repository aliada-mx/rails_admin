module AliadaHelper
   def begin_hours_range(service)
    range_begin = (service.datetime - (1).hour).to_i
    range_end = (service.datetime + (1).hour).to_i

    return (range_begin .. range_end).step(10.minutes)
   end

   def end_hours_range(service)
     end_hours_minimum = service.estimated_hours - 1
     if end_hours_minimum < 3
     then
       end_hours_minimum = 3
     end
    
     range_begin =  (service.datetime + end_hours_minimum.hour).to_i
     range_end =  (service.datetime + (service.estimated_hours + 2).hour).to_i
    
     return (range_begin .. range_end).step(10.minutes)
   end
end
