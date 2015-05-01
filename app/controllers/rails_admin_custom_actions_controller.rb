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
end
