class ServicesController < ApplicationController
  layout 'two_columns'
  load_and_authorize_resource
  skip_authorize_resource only: [:initial, :create_initial, :check_email, :check_postal_code, :incomplete_service]

  before_filter :set_user

  include ServiceHelper

  def initial
    if user_signed_in? 
      if current_user.admin?
        @user = current_user
      else
        redirect_to new_service_users_path(current_user)
      end
    end

    @incomplete_service = IncompleteService.create!
    @service = Service.new(user: User.new,
                           service_type: ServiceType.first,
                           address: Address.new)
  end

  def create_initial
    begin
      service = Service.create_initial!(service_params)
    rescue ActiveRecord::RecordInvalid => invalid
      Raygun.track_exception(invalid)
      return render json: { status: :error, code: :invalid, message: invalid.message }
    rescue Conekta::Error => exception
      Raygun.track_exception(exception)
      return render json: { status: :error, code: :conekta_error, message: [exception.message_to_purchaser]}
    end

    IncompleteService.mark_as_complete(incomplete_service_params,service)

    force_sign_in_user(service.user)

    return render json: { status: :success, service_id: service.id, user_id: service.user.id }
  end

  def new
    # @any_aliada = OpenStruct.new({id: 0, name: 'Cualquier Aliada'})
    # @other_aliada = Aliada.second
    # @first = Aliada.first
  end

  def create_new
    begin
      service = Service.create_new!(service_params, @user)
    rescue ActiveRecord::RecordInvalid => invalid
      Raygun.track_exception(invalid)
      return render json: { status: :error, code: :invalid, message: invalid.message }
    end

    return render json: { status: :success, service_id: service.id }
  end

  def edit
    @service = @user.services.find(params[:service_id])
  end

  def update
    service = @user.services.find(params[:service_id])
    service.update_attributes!(service_params.except(:user, :address))

    next_services_path = next_services_users_path(user_id: @user.id, service_id: service.id)

    return render json: { status: :success, next_path: next_services_path }
  end

  def incomplete_service
    save_incomplete_service

    render nothing: true
  end

  def check_email
    save_incomplete_service

    email = incomplete_service_params[:email]

    if email.present? && User.email_exists?(email)
      return render json: { status: :error, code: :email_already_exists } 
    end
    return render json: { status: :success }
  end

  def check_postal_code
    save_incomplete_service

    postal_code_number = incomplete_service_params[:postal_code_number]

    if postal_code_number.present? && postal_code_number.size >= 4 
      zone = Zone.find_by_postal_code_number(postal_code_number)

      if zone.blank?
        @incomplete_service.update_attributes!(postal_code_not_found: true)
        return render json: { status: :error, code: :postal_code_missing }
      end
    end

    @incomplete_service.update_attributes!(postal_code_not_found: false)
    return render json: { status: :success }
  end

  private
  def save_incomplete_service
    @incomplete_service = IncompleteService.find(params[:incomplete_service][:id])
    @incomplete_service.update_attributes!(incomplete_service_params)
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
                                      :entrance_instructions,
                                      :garbage_instructions,
                                      :cleaning_supplies_instructions,
                                      :attention_instructions,
                                      :equipment_instructions,
                                      :forbidden_instructions,
                                      :special_instructions,
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

  def set_user
    @user = User.find(params[:user_id]) if params.include? :user_id
  end
end
