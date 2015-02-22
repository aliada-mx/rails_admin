class ServicesController < ApplicationController
  layout 'two_columns'

  include ServiceHelper

  def initial
    if user_signed_in?
      redirect_to new_service_users_path(current_user)
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

    #Example of to pass a date into the calendarario.html.erb partial
    @dates =  {Date.new(2015,1,2) => ['8:00', '9:00', '10:00', '11:00', '12:00'] }

    map = {}
    @dates.each_pair do |k,v|
      map[k.strftime('%m-%d-%Y')] = v
    end
    @dates = map
    
    @dates_parsed = ActiveSupport::JSON.encode(@dates).html_safe
  end

  def new
  end

  def update
  end

  def edit
    @service = Service.find(params[:service_id])
  end

  def create
    service = Service.create_initial(service_params)

    redirect_to show_service_users_path(service.user.id, service.id)
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
                                      ]).merge({conekta_temporary_token: params[:conekta_temporary_token] })
                                      
  end
end
