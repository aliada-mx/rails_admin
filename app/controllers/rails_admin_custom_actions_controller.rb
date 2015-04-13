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
end
