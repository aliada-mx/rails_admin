module ServiceHelper
  # Tries to find one of the user addreses
  # matching the postal code or new address
  def suggest_address(user, postal_code)
    addresses = user.addresses.where(postal_code_id: postal_code.id)

    if addresses.exists?
      addresses.first
    else
      Address.new(postal_code_id: postal_code.id)
    end
  end
  
  def service_in_wday_and_hour?(s, wday, t)
    if(s.tz_aware_datetime.wday == wday)
      if((t >= (s.tz_aware_datetime.time.hour*1.hour)) && (t <=(s.tz_aware_datetime.time.hour+s.estimated_hours)*1.hour))
        return true
      end
    else
      return false
    end
  end
end
