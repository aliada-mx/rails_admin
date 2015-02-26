class IncompleteServicesController < ApplicationController
  def update
    incomplete_service = IncompleteService.find(params[:incomplete_service][:id])
    incomplete_service.update_attributes!(incomplete_service_params)

    render nothing: true
  end

  def incomplete_service_params
      params.require(:service).permit(:bathrooms,
                                      :bedrooms,
                                      :estimated_hours,
                                      :service_type_id,
                                      :date,
                                      :time,
                                      ).merge({extra_ids: params[:service][:extra_ids].to_s })
                                       .merge(params[:service][:address_attributes])
                                       .merge(params[:service][:user_attributes])
                                       .except!(:postal_code_id)
  end
end
