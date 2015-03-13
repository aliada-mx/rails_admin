module AliadaHelper
   def begin_hours_range(service)
    range_begin = (service.datetime - (0.5).hour).to_i
    range_end = (service.datetime + (0.5).hour).to_i

    return (range_begin .. range_end).step(5.minutes)
  end

  def end_hours_range(service)
    range_begin =  (service.datetime + (service.estimated_hours - 1).hour).to_i
    range_end =  (service.datetime + (service.estimated_hours + 4).hour).to_i
    
    return (range_begin .. range_end).step((0.25).hour)
  end

end
