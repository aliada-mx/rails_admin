class ServicesController < ApplicationController
  def show
    @service = Service.find_by_id(params[:id])
  end

  def new
    @postal_code = PostalCode.find(params[:postal_code_id])
    @zone = Zone.find_by_postal_code(@postal_code)
    @address = Address.new(postal_code_id: @postal_code.id)
    @service = Service.new(zone_id: @zone.id)
  end

  def create
    @service = Service.create!(service_params)

    redirect_to show_service_path(@service.id)
  end

  private
  def service_params
      params.require(:service).permit(:zone_id, 
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
