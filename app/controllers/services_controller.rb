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
    @service = Service.create!(service_params)

    redirect_to show_service_path(@service.id)
  end

  private
  def service_params
      params.require(:service).permit(:zone_id, 
                                      :service_type_id,
                                      :billable_hours,
                                      :bathrooms,                     
                                      :bedrooms,                      
                                      :aliada_entry_instruction,      
                                      :cleaning_products_instruction, 
                                      :cleaning_utensils_instruction, 
                                      :trash_location_instruction,    
                                      :special_attention_instruction, 
                                      :special_equipment_instruction, 
                                      :do_not_touch_instruction,      
                                      :special_instructions,          
                                      address_attributes: [
                                        :address,         
                                        :between_streets,   
                                        :colony,          
                                        :interior_number, 
                                        :latitude,        
                                        :longitude, 
                                        :municipality,    
                                        :number,          
                                        :postal_code_id,
                                        :state,           
                                      ],
                                     )
  end
end
