# -*- encoding : utf-8 -*-
class RailsAdminCustomActionsController < ApplicationController
  authorize_resource

  def update_object_attribute
    # Dinamically build object
    object_class = params[:object_class].constantize
    object_id = params[:object_id]

    object = object_class.find(object_id)

    attribute = params[:attribute_name]
    value = params[:value]

    object.update_attribute(attribute, value)

    render json: { status: :success, object: object.to_json }
  end

  def get_aliada_schedule
    aliada_id = params[:aliada_id]
    aliada = Aliada.find_by_id( aliada_id );
    render :json => aliada.current_week_services.as_json(:only => [:id, :estimated_hours, :hours_after_service, :user_id, :datetime, :recurrence_id, :service_type_id], :include => { :user => { :only => :full_name } })
  end
end
