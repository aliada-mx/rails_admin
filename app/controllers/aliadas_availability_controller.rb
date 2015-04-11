# -*- encoding : utf-8 -*-
class AliadasAvailabilityController < ApplicationController
  include AliadaSupport::DatetimeSupport
  before_filter :set_user

  rescue_from AliadaExceptions::AvailabilityNotFound do |exception|

    Raygun.track_exception(exception, custom_data: exception.service)
    render json: { status: :error, code: :availability_not_found, message: 'Lo sentimos no encontramos disponibilidad :('}
  end

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
    if zone.nil?
      Raygun.track_exception(AliadaExceptions::AvailabilityNotFound.new(message: "No se encontró zona con disponiblidad", object: params))
      return render json: { status: :success, dates_times: [] }
    end

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

    def set_user
      @user = User.find(params[:user_id]) if params.include? :user_id
    end
end
