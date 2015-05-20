# -*- encoding : utf-8 -*-
class RailsAdminCustomActionsController < ApplicationController
  authorize_resource

  def add_billable_hours_to_service
    service = Service.find(params[:service_id])

    service.billable_hours = params[:value]
    service.finish
    service.save

    render json: { status: :success, object: service.to_json }
  end

  def get_aliada_schedule
    aliada_id = params[:aliada_id]
    init_date = params[:init_date]
    aliada = Aliada.find_by_id( aliada_id );
    #If init_date is send by parameter returns the schedules from date.
    if init_date
      render :json => aliada.week_services( init_date ).as_json(:only => [:id, :estimated_hours, :hours_after_service, :user_id, :datetime, :recurrence_id, :service_type_id], :include => { :user => { :only => :full_name } })
    else
      #If init_date isn't send by parameter returns the schedules from the current week.
      render :json => aliada.current_week_services.as_json(:only => [:id, :estimated_hours, :hours_after_service, :user_id, :datetime, :recurrence_id, :service_type_id], :include => { :user => { :only => :full_name } })
    end
  end
end
