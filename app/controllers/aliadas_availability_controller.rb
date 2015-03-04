class AliadasAvailabilityController < ApplicationController
  def for_calendar
    # We round up because our whole system depends on round hours
    # and its safer to asume more time than less
    hours = params[:hours].to_f.ceil
    hours += Setting.hours_before_service
    hours += Setting.hours_after_service
    
    service_type = ServiceType.find(params[:service_type_id])
    zone = Zone.find_by_postal_code_number(params[:postal_code_number])

    availability = AvailabilityForCalendar.find_availability(hours, 
                                                             recurrent: service_type.recurrent?,
                                                             zone: zone,
                                                             periodicity: service_type.periodicity)

    dates_times = availability.for_calendario

    return render json: { status: :success, dates_times: dates_times }
  end
end
