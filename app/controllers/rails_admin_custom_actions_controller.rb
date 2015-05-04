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
    aliada = Aliada.find_by_id( aliada_id );
    render :json => aliada.current_week_services.as_json(:only => [:id, :estimated_hours, :hours_after_service, :user_id, :datetime, :recurrence_id, :service_type_id], :include => { :user => { :only => :full_name } })
  end
end
