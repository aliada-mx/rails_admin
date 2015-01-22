class ServicesController < ApplicationController
  include ServiceHelper

  def show
    @service = Service.find_by_id(params[:id])
  end

  def new
    @postal_code = PostalCode.find(params[:postal_code_id])
    @zone = Zone.find_by_postal_code(@postal_code)

    if user_signed_in?
      @user = current_user
      @address = suggest_address(@user, @postal_code)
    else
      @user = User.new
      @address = Address.new(postal_code_id: @postal_code.id)
    end

    @service_type = ServiceType.first
    @service = Service.new(user: @user,
                           zone: @zone,
                           service_type: @service_type,
                           address: @address)
  end

  def create
    if user_signed_in?
      @user = current_user
      @user.update!(user_params)

      @address = @user.addresses.find(address_params[:id])
      @address.update!(address_params)
    else
      @user = User.create!(user_params)

      @address = Address.create!(address_params)
    end

    @service = Service.new(service_params)
    @service.address = @address
    @service.user = @user
    @service.aliada = Aliada.first
    @service.create_schedules
    @service.save!

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
                                      :payment_method_id)
  end

  def user_params
    params.require(:service).permit(user: [
                                      :id,
                                      :first_name,
                                      :last_name,
                                      :email,
                                      :phone,
                                    ])[:user]
  end

  def address_params
    params.require(:service).permit(address: [
                                      :id,
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
                                    ])[:address]
  end
end
