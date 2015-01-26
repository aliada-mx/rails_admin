class ServicesController < ApplicationController
  include ServiceHelper

  def show
    @service = Service.find_by_id(params[:id])
  end

  def initial
    if user_signed_in?
      redirect_to new_service_path
    end

    @postal_code = PostalCode.find(params[:postal_code_id])
    @zone = Zone.find_by_postal_code(@postal_code)

    @user = User.new
    @address = Address.new(postal_code_id: @postal_code.id)

    @service_type = ServiceType.first
    @service = Service.new(user: @user,
                           zone: @zone,
                           service_type: @service_type,
                           address: @address)
  end

  def create
    @service = Service.new(service_params)
    @service.save!
    @service.book_aliada!

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
                                      user_attributes: [
                                        :first_name,
                                        :last_name,
                                        :email,
                                        :phone,
                                      ],
                                      address_attributes: [
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
                                      ])
  end
end
