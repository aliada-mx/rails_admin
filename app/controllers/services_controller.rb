class ServicesController < ApplicationController
  layout 'two_columns'

  include ServiceHelper

  def initial
    if user_signed_in?
      redirect_to new_service_users_path(current_user)
    end

    @incomplete_service = IncompleteService.create!
    @service = Service.new(user: User.new,
                           service_type: ServiceType.first,
                           address: Address.new)


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
    service = Service.create_initial!(service_params)

    IncompleteService.mark_as_complete(incomplete_service_params,service)

    redirect_to show_service_users_path(service.user.id, service.id)
  end

  # Provides feedback through ajax to the initial service creation form
  def initial_feedback
    save_incomplete_service

    return if check_email_present

    return if check_postal_code

    return render json: { status: :success }
  end

  private
  def save_incomplete_service
    @incomplete_service = IncompleteService.find(params[:incomplete_service][:id])
    @incomplete_service.update_attributes!(incomplete_service_params)
  end

  def check_email_present
    email = incomplete_service_params[:email]
    return render json: { status: :error, code: :email_already_exists } if email.present? && User.email_exists?(email)
  end

  def check_postal_code
    postal_code = incomplete_service_params[:postal_code]

    if postal_code.present? && postal_code.size >= 4 
      zone = Zone.find_by_code(postal_code)

      if zone.blank?
        return render json: { status: :error, code: :postal_code_missing }
      end
    end
  end

  def incomplete_service_params
      params.require(:service).permit(:bathrooms,
                                      :bedrooms,
                                      :estimated_hours,
                                      :service_type_id,
                                      :date,
                                      :time,
                                      ).merge({extra_ids: params[:service][:extra_ids].to_s })
                                       .merge(params[:service][:address])
                                       .merge(params[:service][:user])
                                       .merge(params[:incomplete_service])
  end

  def service_params
      params.require(:service).permit(:zone_id,
                                      :bathrooms,
                                      :bedrooms,
                                      {extra_ids: []},
                                      :estimated_hours,
                                      :special_instructions,
                                      :service_type_id,
                                      :date,
                                      :time,
                                      :payment_method_id,
                                      :conekta_temporary_token,
                                      :aliada_id,
                                      :incomplete_service_id,
                                      user: [
                                        :first_name,
                                        :last_name,
                                        :email,
                                        :phone,
                                      ],
                                      address: [
                                        :street,
                                        :interior_number,
                                        :number,
                                        :colony,
                                        :between_streets,
                                        :latitude,
                                        :longitude,
                                        :state,
                                        :city,
                                        :references,
                                        :latitude,
                                        :longitude,
                                        :map_zoom,
                                        :postal_code_number,
                                      ]).merge({conekta_temporary_token: params[:conekta_temporary_token] })
                                      
  end
end
