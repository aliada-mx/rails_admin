class AliadasAvailabilityController < ApplicationController
  include AliadaSupport::DatetimeSupport

  def for_calendar
    # We round up because our whole system depends on round hours
    # and its safer to asume more time than less
    hours = params[:hours].to_f.ceil

    aliada_id = params[:aliada_id].to_i if params.include?(:aliada_id) && params[:aliada_id] != '0'

    service_id = params[:service_id].to_i if params.include?(:service_id)
    if service_id
      service = @user.services.find(service_id)
    end

    service_type = ServiceType.find(params[:service_type_id])

    zone = Zone.find_by_postal_code_number(params[:postal_code_number])
    return render json: { status: :success, dates_times: [] } if zone.nil?

    available_after = starting_datetime_to_book_services

    availability = find_availability(hours, zone, available_after, aliada_id, service_type, service: service)

    return render json: { status: :success, dates_times: availability.for_calendario('Mexico City', zone) }
  end

  private
    def find_availability(hours, zone, available_after, aliada_id, service_type, service: nil)
      AvailabilityForCalendar.find_availability(hours, 
                                                zone,
                                                available_after,
                                                aliada_id: aliada_id,
                                                service: service,
                                                recurrent: service_type.recurrent?,
                                                periodicity: service_type.periodicity)
    end
end
