class ServicesController < ApplicationController
  def show
    @service = Service.find_by_id(params[:id])
  end

  def new
    @postal_code = PostalCode.find(params[:postal_code_id])
    @zone = Zone.find_by_postal_code(@postal_code)
    @address = Address.new(postal_code_id: @postal_code.id)
    @service_type = ServiceType.first
    @service = Service.new(zone_id: @zone.id, service_type_id: @service_type.id)
  end

  def create
    @service = Service.create(service_params)
    @service.create_user
    @service.create_schedules

    redirect_to show_service_path(@service.id)
  end

  private
  def service_params
      params.require(:service).permit(:zone_id, 
                                      :bathrooms,                     
                                      :bedrooms,                      
                                      {extra_ids: []},
                                      :billable_hours,
                                      :special_instructions,          
                                      :service_type_id,
                                      :date,
                                      :time,
                                      :payment_method_id,
                                      address_attributes: [
                                        :street,         
                                        :interior_number, 
                                        :number,          
                                        :colony,          
                                        :between_streets,   
                                        :postal_code_id,
                                        :latitude,        
                                        :longitude, 
                                        :state,           
                                        :city,    
                                        :references,
                                      ],
                                      user_attributes: [
                                        :full_name,
                                        :email,
                                        :phone,
                                      ],
                                     )

  end
end
