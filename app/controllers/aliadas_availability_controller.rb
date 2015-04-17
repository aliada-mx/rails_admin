# -*- encoding : utf-8 -*-
class AliadasAvailabilityController < ApplicationController
  include AliadaSupport::DatetimeSupport
  before_filter :set_user

  def for_calendar
    # We round up because our whole system depends on round hours
    # and its safer to asume more time than less
    hours = params[:hours].to_f.ceil

    aliada_id = params[:aliada_id].to_i if params.include?(:aliada_id) && params[:aliada_id] != '0'

    if params.include?(:service_type_id)
      service_type = ServiceType.find(params[:service_type_id].to_i)
    end

    if params.include?(:service_id)
      object = @user.services.find(params[:service_id].to_i)
      service_type = ServiceType.one_time
    end

    if params.include?(:recurrence_id)
      object = @user.recurrences.find(params[:recurrence_id].to_i)
      service_type = ServiceType.recurrent
    end

    zone = Zone.find_by_postal_code_number(params[:postal_code_number])
    if zone.nil?
      Raygun.track_exception(AliadaExceptions::AvailabilityNotFound.new(message: "No se encontró zona con disponiblidad", object: params))
      return render json: { status: :success, dates_times: [] }
    end

    available_after = starting_datetime_to_book_services

    availability = find_availability(hours, zone, available_after, aliada_id, service_type, object: object)

    return render json: { status: :success, dates_times: availability.for_calendario('Mexico City', zone) }
  end

  private
    def find_availability(hours, zone, available_after, aliada_id, service_type, object: nil)
      AvailabilityForCalendar.find_availability(hours, 
                                                zone,
                                                available_after,
                                                aliada_id: aliada_id,
                                                service: object,
                                                recurrent: service_type.recurrent?,
                                                periodicity: service_type.periodicity)
    end

    def set_user
      @user = User.find(params[:user_id]) if params.include? :user_id
    end
end
